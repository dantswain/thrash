defmodule Thrash.Mixfile do
  use Mix.Project

  def project do
    [app: :thrash,
     version: "0.3.2",
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
    [applications: [:logger, :quaff]]
  end

  def elixirc_paths(:bench), do: ["lib", "bench"]
  def elixirc_paths(:test), do: ["lib", "test"]
  def elixirc_paths(_), do: ["lib"]

  defp deps do
    [{:quaff,
      github: "qhool/quaff",
      tag: "9a4ba378d470beac708e366dc9bacd5a9ef6f016",
      override: true,
      only: [:dev, :test, :bench]
     },
     {:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.11", only: :dev},
     {:dialyze, "~> 0.2", only: :dev},
     {:credo, "~> 0.3", only: :dev},
     {:thrift_ex,
      github: "dantswain/thrift_ex",
      only: :bench,
      tag: "f6394871e5685aa1c7e125f198dead0c8a15e992"},
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
