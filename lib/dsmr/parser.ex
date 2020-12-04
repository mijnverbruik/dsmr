defmodule DSMR.Parser do
  @moduledoc false

  import NimbleParsec
  import DSMR.Combinators

  defparsec(:telegram_parser, lines())

  defp format_number({:float, number}), do: {:float, String.to_float(number)}
  defp format_number({:integer, number}), do: {:integer, String.to_integer(number)}

  defp format_timestamp(<<timestamp::binary-size(12), _dst::binary-size(1)>>) do
    timestamp
    |> Timex.parse!("%y%0m%0d%H%M%S", :strftime)
    |> Timex.to_datetime("Europe/Amsterdam")
  end
end
