defmodule DSMR.MixProject do
  use Mix.Project

  @version "0.3.0"
  @url "https://github.com/webstronauts/ex_dsmr"

  def project do
    [
      app: :dsmr,
      version: @version,
      elixir: "~> 1.6",
      deps: deps(),

      # Hex
      package: package(),
      description: "A library for parsing Dutch Smart Meter Requirements (DSMR) telegram data",

      # Docs
      name: "DSMR",
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.15", only: :dev},
      {:nimble_parsec, "~> 1.1"},
      {:timex, "~> 3.6.4"}
    ]
  end

  defp docs() do
    [
      main: "DSMR",
      source_ref: "v#{@version}",
      source_url: @url
    ]
  end

  defp package() do
    [
      maintainers: ["Robin van der Vleuten"],
      licenses: ["Apache 2"],
      links: %{"GitHub" => @url}
    ]
  end
end
