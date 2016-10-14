defmodule Thrash.Mixfile do
  use Mix.Project

  def project do
    [app: :thrash,
     version: "0.1.0",
     description: description,
     package: package,
     elixir: "~> 1.1",
     source_url: "https://github.com/dantswain/thrash",
     docs: [main: "Thrash"],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps]
  end

  def application do
    [applications: [:logger, :thrift]]
  end

  def elixirc_paths(:bench), do: ["lib", "bench"]
  def elixirc_paths(:test), do: ["lib", "test"]
  def elixirc_paths(_), do: ["lib"]

  defp deps do
    [{:earmark, "~> 0.1", only: :dev},
     {:thrift, "~> 1.3"},
     {:ex_doc, "~> 0.11", only: :dev},
     {:dialyze, "~> 0.2", only: :dev},
     {:credo, "~> 0.3", only: :dev},
     {:exprof, "~>0.2", only: :bench},
     {:benchwarmer, "~>0.0.2", only: :bench}]
  end

  defp description do
    """
    Fast serializer/deserializer for Apache Thrift's binary protocol.
    """
  end

  defp package do
    [
      files: ["lib", "LICENSE.txt", "mix.exs", "README.md"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/dantswain/thrash"},
      maintainers: ["Dan Swain"]
    ]
  end
end
