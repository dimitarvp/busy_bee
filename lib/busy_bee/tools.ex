defmodule BusyBee.Tools do
  @doc """
  Finds the identifiers of all workers in a pool with the specified name.
  Each of the identifiers can be used as a first argument to `GenServer.call`.
  """
  def worker_ids(name) do
    name
    |> Supervisor.which_children()
    |> Enum.filter(&valid_worker?/1)
    |> Enum.map(&worker_id/1)
  end

  @doc """
  Checks if a value returned by `Supervisor.which_children/1` is a valid worker, i.e. one with
  non-`nil` and non-`:unfedined` ID and of the `:worker` type.
  """
  def valid_worker?({nil, _pid, _type, _modules}), do: false
  def valid_worker?({:undefined, _pid, _type, _modules}), do: false
  def valid_worker?({_id, _pid, :worker, _modules}), do: true
  def valid_worker?(_), do: false

  @doc """
  Extracts an ID from a value returned by `Supervisor.which_children/1` and only if it's a worker.
  Returns `nil` on any other input shape.
  """
  def worker_id({id, _pid, :worker, _modules}), do: id
  def worker_id(_), do: nil

  @doc """
  Similar to `Enum.zip/2` but also wraps around the second list argument f.ex.
  `zip_cycle([1, 2, 3, 4], [:x, :y, :z])` yields `[{1, :x}, {2, :y}, {3, :z}, {4, :x}]`.
  It never produces more items than the length of the first list.
  """
  def zip_cycle([h0 | t0] = _l0, [h1 | t1] = l1),
    do: zip_cycle(t0, t1, l1, [{h0, h1}])

  def zip_cycle(_l0, _l1), do: []

  defp zip_cycle([h0 | t0], [h1 | t1], l1, acc),
    do: zip_cycle(t0, t1, l1, [{h0, h1} | acc])

  defp zip_cycle([h0 | t0], [], [h1 | t1] = l1, acc),
    do: zip_cycle(t0, t1, l1, [{h0, h1} | acc])

  defp zip_cycle([], _, _, acc),
    do: :lists.reverse(acc)
end
