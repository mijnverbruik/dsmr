defmodule DSMR.Parser do
  @moduledoc false

  import NimbleParsec
  import DSMR.Combinators

  defparsec(:telegram_parser, lines())

  defp format_value({:float, number}), do: {:float, String.to_float(number)}
  defp format_value({:integer, number}), do: {:integer, String.to_integer(number)}

  defp format_value({:timestamp, <<timestamp::binary-size(12), _dst::binary-size(1)>>}) do
    timestamp
    |> Timex.parse!("%y%0m%0d%H%M%S", :strftime)
    |> Timex.to_datetime("Europe/Amsterdam")

    {:timestamp, timestamp}
  end

  defp format_value(value), do: value
end
