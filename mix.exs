defmodule Auth0.MixProject do
  use Mix.Project

  @source_url "https://github.com/JosePamplona/Auth0-M2M-Interface"
  @version    "0.1.0"

  def project do
    [
      app: :auth0,
      version:  @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),

      # ExDocs documentation parameters
      name: "Auth0 M2M Interface",
      source_url: @source_url,
      docs: [
        authors: ["José Pamplona"],
        main: "readme",
        logo: "assets/logo.png",
        assets: "assets",
        extras:  [
          "README.md": [title: "Overview"],
          "LICENSE.md": [title: "License"],
          "CHANGELOG.md": [title: "Changelog"]
        ]
      ],
  
      # Hexdocs package metadata
      package: package(),
      description: "Interface module for authenticate Auth0 Machine-to-Machine applications and perform requests to the Auth0 Management API."
    ]
  end

  defp package(), do: [
    licenses: ["MIT"],
    links: %{"GitHub" => @source_url},
    files: ~w(lib mix.exs README.md LICENSE.md CHANGELOG.md),
    maintainers: ["José Pamplona"]
  ]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [mod: {Auth0.Application, []}]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [      
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:finch, "~> 0.16"},
      {:jason, "~> 1.2"},
      {:mock, "~> 0.3", only: :test}
    ]
  end
end
