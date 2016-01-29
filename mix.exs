defmodule Thrash.Mixfile do
  use Mix.Project

  def project do
    [app: :thrash,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     erlc_options: [:bin_opt_info],
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  def elixirc_paths(:dev), do: ["lib", "bench"]
  def elixirc_paths(:test), do: ["lib", "test"]
  def elixirc_paths(_), do: ["lib"]

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:thrift_ex, github: "dantswain/thrift_ex"},
     {:quaff, github: "qhool/quaff"},
     {:benchwarmer, "~>0.0.2", only: :dev}]
  end
end
