defmodule D2lvalenceElixir.Mixfile do
  use Mix.Project

  def project do
    [
      app: :d2lvalence_elixir,
      version: "0.1.0",
      elixir: "~> 1.12",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),

      # Docs
      name: "D2lvalenceElixir",
      source_url: "https://github.com/chrisapa/d2lvalence_elixir",
      homepage_url: "https://github.com/chrisapa/d2lvalence_elixir",
      docs: [
        # The main page in the docs
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Christian Aparicio Baquen (chris_apa)"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/chrisapa/d2lvalence_elixir",
        "Docs" => "https://hexdocs.pm/d2lvalence_elixir/"
      }
    ]
  end

  defp description do
    """
    Elixir implementation of d2lvalence to connect to the Desire2Learn's Valence API (Brightspace)
    """
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hackney, "~> 1.17"},
      {:jason, "~> 1.2"},
      {:ex_doc, "~> 0.11", only: :dev},
      {:earmark, "~> 0.1", only: :dev}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
