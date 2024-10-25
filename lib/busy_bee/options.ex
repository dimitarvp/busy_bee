defmodule BusyBee.Options do
  @defaults [
    caller_supervisor: BusyBee.CallerSupervisor,
    call_timeout: 5_000,
    shutdown_timeout: 15_000,
    workers: System.schedulers_online(),
    callers: nil,
    name: BusyBee
  ]

  @doc """
  This function:
  - `Keyword.merge`s the defaults with the given options;
  - Makes sure that `:workers` and `:callers` are >= 2 (uses `System.schedulers_online()` if not);
  - Makes sure that caller count is never less than worker count;
  - Returns the modified options keyword list.
  """
  def new(opts) do
    # Merges the defaults with the given options and makes sure worker count is valid.
    opts =
      @defaults
      |> Keyword.merge(opts)
      |> replace_if_invalid(
        :workers,
        fn x -> is_integer(x) and x >= 2 end,
        System.schedulers_online()
      )

    workers = Keyword.fetch!(opts, :workers)

    # Makes sure the caller count is valid and is never less than the worker count.
    replace_if_invalid(opts, :callers, fn x -> is_integer(x) and x >= workers end, workers)
  end

  defp replace_if_invalid(opts, key, validator_fn, default_value)
       when is_list(opts) and is_atom(key) and is_function(validator_fn, 1) do
    value = Keyword.get(opts, key)

    if validator_fn.(value) do
      opts
    else
      Keyword.put(opts, key, default_value)
    end
  end
end
