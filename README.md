# BusyBee

### Synopsis

This is a micro task pool library that provides a unique VM/node-wide task pool named by the user (so you can have any number of them as long as the names are unique) whose gimmick is that it keeps the worker processes alive for as long as the task pool itself (a `Supervisor`) is alive. When work needs to be done (via the `each/2` function) it spawns throwaway processes to process an input list of items with a given function, using the workers in the pool, in parallel. The amount of these throwaway processes (we call them "callers") can be equal to or more than the worker count -- but never less.

### Usage

The intended usage of this task pool is to define a module and do `use BusyBee` inside it, akin to an `Ecto.Repo`, like so:

```elixir
defmodule MyApp.SendEmails do
  use BusyBee, workers: 3, call_timeout: :infinity, shutdown_timeout: :30_000
end
```

This injects a bunch of code in this `use`-ing module that provides `Supervisor` wiring and also the `each/2` function that provides parallel execution of work utilizing the workers in the pool, in parallel.

This library is not intended for distribution; it provides no guarantees in that regard.

### Use cases

The author has successfully used this library in the following scenarios:

- In a job: to have an unique VM/node-wide task pool in order to ensure small load to a very limited external resource (a 3rd party API). We have given very generous timeout values to the task pool and just let our background workers call the pool's `each/2` function without worrying about manually throttling the access to the external resource. This has worked very well and allowed us to avoid HTTP 429 errors until we later eventually moved to Oban Pro.
- In a personal project: this task pool has been useful for the author's financial trading bot experiments as it allows processing of huge amounts of data pieces without much considerations of the OTP wiring involved -- and the Elixir API used by this micro library allows proper supervision and process linking so any errors have become immediately apparent and were easy to remedy.

In conclusion, I don't claim that this is a game-breakingly useful library. It was half (1) an exercise in understanding and utilizing OTP to the best of its abilities to do a lot of parallel work, and (2) half a way to reduce code boilerplate and provide better abstractions in several projects, professional and hobby alike.
