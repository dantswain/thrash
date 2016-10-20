# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# If this ever gets more complex, switch to separate .exs files
defmodule Config do
  def idl_files(:test), do: Path.wildcard("test/thrift/**/*.thrift")
  def idl_files(_), do: []
end

config :thrash,
  idl_files: Config.idl_files(Mix.env)
