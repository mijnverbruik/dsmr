defmodule DSMR do
  @moduledoc """
  A library for parsing Dutch Smart Meter Requirements (DSMR) telegram data.
  """

  alias DSMR.Telegram

  defmodule ParseError do
    @type t() :: %__MODULE__{}

    defexception [:message]
  end

  @doc """
  Parses telegram data from a string and returns a struct.

  If the telegram is parsed successfully, this function returns `{:ok, telegram}`
  where `telegram` is a `DSMR.Telegram` struct. If the parsing fails, this
  function returns `{:error, parse_error}` where `parse_error` is a `DSMR.ParseError` struct.
  You can use `raise/1` with that struct or `Exception.message/1` to turn it into a string.
  """
  @spec parse(String.t()) :: {:ok, Telegram.t()} | {:error, ParseError.t()}
  def parse(string) do
    with {:ok, parsed, "", _, _, _} <- DSMR.Parser.telegram_parser(string),
         {:ok, telegram} <- create_telegram(parsed) do
      {:ok, telegram}
    else
      _ ->
        {:error, %ParseError{message: "Could not parse #{inspect(string)}."}}
    end
  end

  @doc """
  Parses telegram data from a string and raises if the data cannot be parsed.

  This function behaves exactly like `parse/1`, but returns the telegram directly
  if parsed successfully or raises a `DSMR.ParseError` exception otherwise.
  """
  @spec parse!(String.t()) :: Telegram.t()
  def parse!(string) do
    case parse(string) do
      {:ok, telegram} -> telegram
      {:error, %ParseError{} = error} -> raise error
    end
  end

  defp create_telegram(parsed) do
    telegram =
      Enum.reduce(parsed, %Telegram{}, fn line, telegram ->
        case line do
          {:header, header} ->
            %{telegram | header: Telegram.Header.new(header)}

          {:cosem, [{:obis, [0, channel, 24, 1, 0]} | _value] = mbus} ->
            append_mbus(telegram, channel, mbus)

          {:cosem, [{:obis, [0, channel, 96, 1, 0]} | _value] = mbus} ->
            append_mbus(telegram, channel, mbus)

          {:cosem, [{:obis, [0, channel, 24, 2, 1]} | _values] = mbus} ->
            append_mbus(telegram, channel, mbus)

          {:cosem, cosem} ->
            append_cosem(telegram, cosem)

          {:footer, checksum} ->
            %{telegram | checksum: Telegram.Checksum.new(checksum)}
        end
      end)

    {:ok, telegram}
  end

  defp append_cosem(telegram, cosem) do
    %{telegram | data: telegram.data ++ [Telegram.COSEM.new(cosem)]}
  end

  defp append_mbus(telegram, channel, cosem) do
    if index = find_mbus_index(telegram.data, channel) do
      new_mbus = Telegram.MBus.new(channel, cosem)

      mbus = Enum.fetch!(telegram.data, index)
      mbus = %{mbus | data: mbus.data ++ new_mbus.data}

      %{telegram | data: List.replace_at(telegram.data, index, mbus)}
    else
      mbus = Telegram.MBus.new(channel, cosem)
      %{telegram | data: telegram.data ++ [mbus]}
    end
  end

  defp find_mbus_index(data, channel) when is_list(data) do
    Enum.find_index(data, &find_mbus_index(&1, channel))
  end

  defp find_mbus_index(%Telegram.MBus{} = mbus, channel), do: mbus.channel == channel
  defp find_mbus_index(_cosem, _channel), do: false
end
