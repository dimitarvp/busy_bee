defmodule BusyBee.Supervisor do
  use Supervisor

  alias BusyBee.Options

  def child_spec(opts) do
    opts = Options.new(opts)
    name = Keyword.fetch!(opts, :name)
    shutdown_timeout = Keyword.fetch!(opts, :shutdown_timeout)

    %{
      id: name,
      restart: :permanent,
      shutdown: shutdown_timeout,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  def start_link(opts) do
    opts = Options.new(opts)
    name = Keyword.fetch!(opts, :name)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl Supervisor
  def init(opts) do
    opts = Options.new(opts)
    name = Keyword.fetch!(opts, :name)
    workers = Keyword.fetch!(opts, :workers)

    children =
      for i <- 1..workers do
        opts
        |> Keyword.put(:name, Module.concat([name, BusyBee.Worker, Integer.to_string(i)]))
        |> BusyBee.Worker.child_spec()
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
