defmodule BusyBee do
  @moduledoc """
  This is a module that's meant to be `use`-d so it injects code in the using module;
  it allows the using module to be a supervisor for a named task pool.

  Special attention deserves the `each` function that allows a list be processed
  with a given function through the task pool, in parallel.
  """

  alias BusyBee.{Options, Tools}

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use Supervisor

      @name Keyword.get(opts, :name, __MODULE__)
      @opts opts |> Options.new() |> Keyword.put(:name, @name)
      @workers Keyword.fetch!(@opts, :workers)
      @callers Keyword.fetch!(@opts, :callers)
      @caller_supervisor Keyword.fetch!(@opts, :caller_supervisor)
      @call_timeout Keyword.fetch!(@opts, :call_timeout)
      @shutdown_timeout Keyword.fetch!(@opts, :shutdown_timeout)

      @doc """
      The `Supervisor` id / name of this worker pool. NOTE: not specifying a name will register
      and start a global pool that *cannot* be started more than once.

      Defaults to the name of the module that does `use BusyBee`.
      """
      def name(), do: @name

      @doc """
      The amount of workers this pool will distribute tasks to.
      The worker processes are *always* live; they do NOT get stopped when there is no work.
      There will never be more than this amount of processes doing work in parallel for this pool.

      Defaults to `System.schedulers_online()`.
      """
      def workers(), do: @workers

      @doc """
      The amount of throwaway processes that this pool will spawn that will do `GenServer.call`
      on the workers. Can never be smaller than the worker count. This setting controls worker
      contention; if it's the same value as `workers` then the pool is doing 1:1 full parallel
      execution. If the callers are more than the workers then the callers will each wait their
      turn to receive a designated worker that calls their function.

      Defaults to the worker count.
      """
      def callers(), do: @callers

      @doc """
      The name of the `Task.Supervisor` under which you want the throwaway caller processes
      to be spawned. NOTE: you have to have started this supervisor on your own beforehand.

      This library starts a default one if you don't want to start your own; so just omit
      this option and the caller (throwaway) processes will be started under it.
      """
      def caller_supervisor(), do: @caller_supervisor

      @doc """
      The caller (throwaway process) timeout; the callers do a `GenServer.call` with
      infinite timeout so the work itself will not be disrupted but the callers can and will
      be killed if they exceed this timeout.

      Defaults to `5_000` ms.
      """
      def call_timeout(), do: @call_timeout

      @doc """
      How much milliseconds to wait for a worker to shutdown when the supervisor is stopped.

      Defaults to `15_000` ms.
      """
      def shutdown_timeout(), do: @shutdown_timeout

      @doc """
      Return the pool options.
      """
      def opts(), do: @opts

      def child_spec(child_spec_opts) do
        # Whatever is given in the childspec (inside the app supervision tree)
        # always takes a precendence over the options given to the `use` macro.
        start_link_opts =
          Keyword.merge(@opts, child_spec_opts, fn _k, v1, v2 -> v2 || v1 end)

        %{
          id: @name,
          restart: :permanent,
          shutdown: @shutdown_timeout,
          start: {__MODULE__, :start_link, [start_link_opts]},
          type: :supervisor
        }
      end

      def start_link(opts) do
        Supervisor.start_link(__MODULE__, opts, name: @name)
      end

      @impl Supervisor
      def init(opts) do
        shutdown_timeout = Keyword.fetch!(opts, :shutdown_timeout)

        children =
          for i <- 1..@workers do
            worker_name = Module.concat([@name, BusyBee.Worker, Integer.to_string(i)])

            %{
              id: worker_name,
              restart: :permanent,
              shutdown: shutdown_timeout,
              start: {BusyBee.Worker, :start_link, [worker_name]},
              type: :worker
            }
          end

        Supervisor.init(children, strategy: :one_for_one)
      end

      @doc """
      Process all items in the input list with the given function and using the workers
      in this pool.
      """
      def each(items, fun) when is_function(fun, 1) do
        worker_ids = Tools.worker_ids(@name)
        task_and_worker_id_pairs = Tools.zip_cycle(items, worker_ids)

        Task.Supervisor.async_stream_nolink(
          @caller_supervisor,
          task_and_worker_id_pairs,
          fn {item, worker_id} ->
            # The core value proposition of this library: namely a VM-wide task pool.
            # We serialize calls to the same worker so we never run more than the configured
            # amount of them at the same time. We might have a huge amount of callers but the
            # amount of workers is limited and callers will wait their turn.
            # This here is the caller.
            GenServer.call(worker_id, {:run, fun, item}, :infinity)
          end,
          max_concurrency: @callers,
          timeout: @call_timeout,
          on_timeout: :kill_task
        )
        |> Stream.run()
      end
    end
  end
end
