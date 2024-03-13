defmodule DSMR.MixProject do
  use Mix.Project

  @source_url "https://github.com/mijnverbruik/ex_dsmr"
  @version "0.3.0"

  def project do
    [
      app: :dsmr,
      version: @version,
      elixir: "~> 1.11",
      name: "DSMR",
      description: "A library for parsing Dutch Smart Meter Requirements (DSMR) telegram data",
      compilers: compilers(),
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  defp compilers do
    [:yecc] ++ Mix.compilers()
  end

  defp deps do
    [
      {:benchee, "~> 1.3", only: :dev},
      {:decimal, "~> 2.0", optional: true},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:nimble_parsec, "~> 1.4"}
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
      links: %{"GitHub" => @source_url}
    ]
  end
end
