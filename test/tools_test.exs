defmodule BusyBee.ToolsTest do
  use ExUnit.Case
  doctest BusyBee.Tools

  alias BusyBee.Tools

  describe "zip_cycle/2" do
    test "two empty lists yield an empty list" do
      assert Tools.zip_cycle([], []) == []
    end

    test "two lists with single elements work" do
      assert Tools.zip_cycle([1], [2]) == [{1, 2}]
    end

    test "does not wrap around the first list" do
      assert Tools.zip_cycle([1, 2], [:a, :b, :c]) == [{1, :a}, {2, :b}]
    end

    test "wraps around the second list" do
      assert Tools.zip_cycle([1, 2, 3], [:a, :b]) == [{1, :a}, {2, :b}, {3, :a}]
    end

    test "returns empty list on invalid input" do
      assert [] == Tools.zip_cycle(nil, :huh)
      assert [] == Tools.zip_cycle("hello", 123.456)
      assert [] == Tools.zip_cycle(false, <<11, 17, 98>>)
    end
  end

  describe "worker_id/1" do
    test "finds the ID of a valid worker spec" do
      assert Tools.worker_id({:a_name, 123, :worker, [List, Enum]}) == :a_name
    end

    test "returns nil when given an invalid worker spec" do
      assert nil == Tools.worker_id({:a_name, "other", :stuff, "here"})
    end
  end

  describe("valid_worker?/1") do
    test "nil id yields false" do
      refute Tools.valid_worker?({nil, 123, :supervisor, [List, Enum]})
    end

    test ":undefined id yields false" do
      refute Tools.valid_worker?({:undefined, 123, :worker, [List, Enum]})
    end

    test "valid worker id yields true" do
      assert Tools.valid_worker?({:a, 123, :worker, [List, Enum]})
    end

    test "valid supervisor id yields false" do
      refute Tools.valid_worker?({:a, 123, :supervisor, [List, Enum]})
    end

    test "non-tuple value yields false" do
      refute Tools.valid_worker?([:whatever, 123, "hello"])
    end
  end

  describe "worker_ids/1" do
    test "can find the worker IDs of a successfully started pool" do
      spec =
        {BusyBee.Supervisor,
         name: Whatever, workers: 3, callers: 5, spawn_timeout: 5_000, shutdown_timeout: 30_000}

      pool = start_supervised!(spec)
      assert is_pid(pool)

      assert Whatever |> Tools.worker_ids() |> Enum.sort() == [
               Module.concat([Whatever, BusyBee.Worker, "1"]),
               Module.concat([Whatever, BusyBee.Worker, "2"]),
               Module.concat([Whatever, BusyBee.Worker, "3"])
             ]
    end
  end
end
