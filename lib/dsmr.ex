defmodule DSMR do
  def parse(string) do
    with {:ok, parsed, "", _, _, _} <- DSMR.Parser.telegram_parser(string) do
      {:ok, parsed}
    else
      _ ->
        {:error, {DSMR.ParseError, "Could not parse #{inspect(string)}."}}
    end
  end
end
