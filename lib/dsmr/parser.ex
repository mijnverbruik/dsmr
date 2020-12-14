defmodule DSMR.Parser do
  @moduledoc false

  import NimbleParsec
  import DSMR.Combinators

  defparsec(:telegram_parser, lines())

  defp format_value({:float, value}), do: [{:float, String.to_float(value)}, {:raw, value}]
  defp format_value({:integer, value}), do: [{:integer, String.to_integer(value)}, {:raw, value}]

  defp format_value({:timestamp, <<timestamp::binary-size(12), _dst::binary-size(1)>> = value}) do
    timestamp
    |> Timex.parse!("%y%0m%0d%H%M%S", :strftime)
    |> Timex.to_datetime("Europe/Amsterdam")

    [{:timestamp, timestamp}, {:raw, value}]
  end

  defp format_value({:unit, _unit} = value), do: value
  defp format_value({type, value}), do: [{type, value}, {:raw, value}]
end
