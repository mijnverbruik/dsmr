defmodule DSMR do
  alias DSMR.Telegram

  def parse(string) do
    with {:ok, parsed, "", _, _, _} <- DSMR.Parser.telegram_parser(string) do
      create_telegram(parsed)
    else
      _ ->
        {:error, {DSMR.ParseError, "Could not parse #{inspect(string)}."}}
    end
  end

  defp create_telegram(parsed) do
    telegram =
      Enum.reduce(parsed, %Telegram{}, fn line, telegram ->
        case line do
          {:header, header} ->
            %{telegram | header: Telegram.Header.new(header)}

          {:cosem, cosem} ->
            %{telegram | data: telegram.data ++ [Telegram.COSEM.new(cosem)]}

          {:footer, checksum} ->
            %{telegram | checksum: Telegram.Checksum.new(checksum)}
        end
      end)

    {:ok, telegram}
  end
end
