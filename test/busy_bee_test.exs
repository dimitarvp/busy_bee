defmodule BusyBeeTest do
  use ExUnit.Case
  doctest BusyBee

  test "check if options are passed and stored correctly" do
    defmodule TestPool_0 do
      use BusyBee,
        workers: 3,
        callers: 5,
        call_timeout: 6_000,
        shutdown_timeout: 30_000
    end

    assert TestPool_0.opts() == [
             name: BusyBeeTest.TestPool_0,
             caller_supervisor: BusyBee.CallerSupervisor,
             workers: 3,
             callers: 5,
             call_timeout: 6000,
             shutdown_timeout: 30000
           ]

    assert TestPool_0.name() == BusyBeeTest.TestPool_0
    assert TestPool_0.caller_supervisor() == BusyBee.CallerSupervisor
    assert TestPool_0.workers() == 3
    assert TestPool_0.callers() == 5
    assert TestPool_0.call_timeout() == 6000
    assert TestPool_0.shutdown_timeout() == 30000
  end
end
