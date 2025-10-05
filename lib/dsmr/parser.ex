defmodule DSMR.Parser do
  @moduledoc false

  alias DSMR.{MBusDevice, Measurement, Telegram, Timestamp}

  @doc """
  Parses DSMR telegram input into a structured Telegram.

  Returns `{:ok, telegram}` on success.

  On error, returns:
  - `{:error, {line, :dsmr_lexer, reason}, rest}` for lexical errors
  - `{:error, {line, :dsmr_parser, message}}` for parse errors
  """
  @spec parse(binary(), keyword()) ::
          {:ok, Telegram.t()} | {:error, term(), term()} | {:error, term()}
  def parse(input, options) do
    opts = %{floats: Keyword.get(options, :floats, :native)}

    with {:ok, tokens} <- do_lex(input),
         {:ok, _telegram} = result <- do_parse(tokens, opts) do
      result
    end
  end

  defp do_lex(string) when is_binary(string) do
    string |> to_charlist() |> do_lex()
  end

  defp do_lex(chars) do
    case :dsmr_lexer.string(chars) do
      {:ok, tokens, _} ->
        {:ok, tokens}

      {:error, error_tuple, rest} ->
        {:error, error_tuple, rest}
    end
  end

  defp do_parse(tokens, opts) do
    case :dsmr_parser.parse(tokens) do
      {:ok, parsed} ->
        [{:header, header}, {:checksum, checksum}, {:data, data}] = parsed
        telegram = %Telegram{header: header, checksum: checksum}

        {telegram_fields, mbus_fields} =
          data
          |> Enum.split_with(fn
            {:telegram_field, _, _} -> true
            {:mbus_field, _, _, _} -> false
            {:unknown_obis, _, _} -> false
          end)

        # Process telegram fields
        telegram =
          telegram_fields
          |> Enum.reduce(telegram, fn {:telegram_field, field, attrs}, acc ->
            process_telegram_field(acc, field, attrs, opts)
          end)

        # Process MBus device fields grouped by channel
        mbus_devices =
          mbus_fields
          |> Enum.group_by(fn {:mbus_field, channel, _, _} -> channel end)
          |> Enum.sort_by(fn {channel, _} -> channel end)
          |> Enum.map(fn {channel, fields} ->
            process_mbus_device(channel, fields, opts)
          end)

        {:ok, %{telegram | mbus_devices: mbus_devices}}

      {:error, error_tuple} ->
        {:error, error_tuple}
    end
  end

  # Process telegram field - now field name comes from parser
  defp process_telegram_field(telegram, :power_failures_log, value, opts) do
    # Special case: power failures log with nested structure
    [{:string, count_str}, {:obis, {[0, 0, 96, 7, 19], _}} | events] = value
    count = String.to_integer(count_str)

    # Each event consists of 2 elements (timestamp and duration)
    actual_count = div(length(events), 2)

    if actual_count != count do
      raise ArgumentError,
            "Power failures log count mismatch: expected #{count} events, but got #{actual_count}"
    end

    events =
      events
      |> Enum.map(&extract_value(&1, opts))
      |> Enum.chunk_every(2)

    %{telegram | power_failures_log: events}
  end

  defp process_telegram_field(telegram, field, value, opts) do
    Map.put(telegram, field, extract_value(value, opts))
  end

  # Process MBus device from grouped fields
  defp process_mbus_device(channel, fields, opts) do
    Enum.reduce(fields, %MBusDevice{channel: channel}, fn
      {:mbus_field, _, :device_type, attrs}, mbus_device ->
        %{mbus_device | device_type: extract_value(attrs, opts)}

      {:mbus_field, _, :equipment_id, attrs}, mbus_device ->
        %{mbus_device | equipment_id: extract_value(attrs, opts)}

      {:mbus_field, _, :last_reading, attrs}, mbus_device ->
        [measured_at, value] = attrs

        %{
          mbus_device
          | last_reading_measured_at: extract_value(measured_at, opts),
            last_reading_value: extract_value(value, opts)
        }

      {:mbus_field, _, :valve_position, attrs}, mbus_device ->
        %{mbus_device | valve_position: extract_value(attrs, opts)}

      {:mbus_field, _, :legacy_gas_reading, attrs}, mbus_device ->
        [
          {:string, timestamp},
          _,
          _,
          _,
          {:obis, {[0, 1, 24, 2, 1], _}},
          {:string, unit},
          {:string, value}
        ] =
          attrs

        measurement = %Measurement{unit: unit, value: extract_value({:float, value}, opts)}
        timestamp = extract_value({:timestamp, timestamp}, opts)

        %{mbus_device | last_reading_value: measurement, last_reading_measured_at: timestamp}
    end)
  end

  defp extract_value([value], opts), do: extract_value(value, opts)
  defp extract_value(nil, _opts), do: nil

  defp extract_value({:measurement, {value, unit}}, opts) do
    processed_value = extract_value(value, opts)
    %Measurement{unit: unit, value: processed_value}
  end

  defp extract_value({:timestamp, {value, dst}}, _opts) do
    [year, month, day, hour, minute, second] = value
    timestamp = NaiveDateTime.new!(2000 + year, month, day, hour, minute, second)
    %Timestamp{value: timestamp, dst: dst}
  end

  defp extract_value({:timestamp, value}, opts) when is_binary(value) do
    extract_value(
      {:timestamp,
       {value
        |> String.split(~r/.{2}/, include_captures: true, trim: true)
        |> Enum.map(&:erlang.binary_to_integer/1), nil}},
      opts
    )
  end

  defp extract_value({:float, value}, %{floats: :native} = _opts) do
    :erlang.binary_to_float(value)
  end

  defp extract_value({:float, value}, %{floats: :decimals} = _opts) do
    # silence xref warning
    decimal = Decimal
    decimal.new(value)
  end

  defp extract_value({:int, value}, _opts) do
    :erlang.binary_to_integer(value)
  end

  defp extract_value({_token, value}, _opts) do
    value
  end
end
