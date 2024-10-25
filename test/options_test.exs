defmodule OptionsTest do
  use ExUnit.Case
  doctest BusyBee.Options
  alias BusyBee.Options

  @default_workers System.schedulers_online()

  describe "worker count" do
    test "value of nil yields a default" do
      assert Options.new(workers: nil) |> Keyword.get(:workers) == @default_workers
    end

    test "value of zero yields a default" do
      assert Options.new(workers: 0) |> Keyword.get(:workers) == @default_workers
    end

    test "value of one yields a default" do
      assert Options.new(workers: 1) |> Keyword.get(:workers) == @default_workers
    end

    test "value of two works" do
      assert Options.new(workers: 2) |> Keyword.get(:workers) == 2
    end

    test "wrong type value yields a default" do
      assert Options.new(workers: "x") |> Keyword.get(:workers) == @default_workers
    end
  end

  describe "caller count" do
    test "value of nil yields a default" do
      assert Options.new(callers: nil) |> Keyword.get(:callers) == @default_workers
    end

    test "value of zero yields a default" do
      assert Options.new(callers: 0) |> Keyword.get(:callers) == @default_workers
    end

    test "value of one yields a default" do
      assert Options.new(callers: 1) |> Keyword.get(:callers) == @default_workers
    end

    test "value of two works" do
      assert Options.new(workers: 2, callers: 2) |> Keyword.get(:callers) == 2
    end

    test "wrong type value yields a default" do
      assert Options.new(callers: "x") |> Keyword.get(:callers) == @default_workers
    end

    test "can never be less than the worker count" do
      assert Options.new(workers: 3, callers: 2) |> Keyword.get(:callers) == 3
    end

    test "default is equal to worker count" do
      assert Options.new(workers: 7) |> Keyword.get(:callers) == 7
    end
  end
end
