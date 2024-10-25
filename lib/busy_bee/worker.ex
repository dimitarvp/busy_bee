defmodule BusyBee.Worker do
  @doc """
  This is a `GenServer` that accepts a function with a single argument and executes it.
  """

  use GenServer

  # Server (callbacks)

  @impl GenServer
  def init(_state) do
    {:ok, _state = []}
  end

  @impl GenServer
  def handle_call({:run, fun, arg}, _from, _state = []) when is_function(fun, 1) do
    {:reply, _return_value = fun.(arg), _state = []}
  end

  # Client

  def child_spec(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    shutdown_timeout = Keyword.get(opts, :shutdown_timeout, 15_000)

    %{
      id: name,
      restart: :permanent,
      shutdown: shutdown_timeout,
      start: {__MODULE__, :start_link, [name]},
      type: :worker
    }
  end

  def start_link(name) do
    GenServer.start_link(__MODULE__, _state = [], name: name)
  end
end
