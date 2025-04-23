defmodule DSMR.MixProject do
  use Mix.Project

  @source_url "https://github.com/mijnverbruik/dsmr"
  @version "0.5.0"

  def project do
    [
      app: :dsmr,
      version: @version,
      elixir: "~> 1.14",
      deps: deps(),
      compilers: [:leex, :yecc] ++ Mix.compilers(),

      # Hex
      package: package(),
      description: "A library for parsing Dutch Smart Meter Requirements (DSMR) telegram data",

      # Docs
      name: "DSMR",
      docs: docs()
    ]
  end

  defp deps do
    [
      {:benchee, "~> 1.3", only: :dev},
      {:decimal, "~> 2.0", optional: true},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "DSMR",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      maintainers: ["Robin van der Vleuten"],
      files: ["lib", "mix.exs", "README*", "CHANGELOG*", "LICENSE", "src"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
