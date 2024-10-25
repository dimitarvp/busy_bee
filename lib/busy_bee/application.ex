defmodule BusyBee.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: BusyBee.CallerSupervisor}
    ]

    opts = [strategy: :one_for_one, name: BusyBee.AppSupervisor]
    Supervisor.start_link(children, opts)
  end
end
