defmodule DSMR.Parser do
  @moduledoc false

  alias DSMR.{MBusDevice, Measurement, Telegram, Timestamp}

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
    with {:ok, tokens, _} <- :dsmr_lexer.string(chars) do
      {:ok, tokens}
    end
  end

  defp do_parse(tokens, opts) do
    with {:ok, parsed} <- :dsmr_parser.parse(tokens) do
      [{:header, header}, {:checksum, checksum}, {:data, data}] = parsed
      telegram = %Telegram{header: header, checksum: checksum}

      {objects, channels} =
        data
        |> Enum.group_by(&group_by_mbus_channels/1)
        |> Map.pop(0, [])

      telegram =
        objects
        |> Enum.reduce(telegram, &attrs_from_object(&1, &2, opts))
        |> Map.put(:mbus_devices, Enum.map(channels, &attrs_from_mbus_device(&1, opts)))

      {:ok, telegram}
    end
  end

  defp attrs_from_mbus_device({channel, objects}, opts) do
    Enum.reduce(objects, %MBusDevice{channel: channel}, &attrs_from_object(&1, &2, opts))
  end

  defp attrs_from_object([{:obis, [1, 3, 0, 2, 8]}, value], %Telegram{} = telegram, opts) do
    %{telegram | version: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [0, 0, 1, 0, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | measured_at: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [0, 0, 96, 1, 1]}, value], %Telegram{} = telegram, opts) do
    %{telegram | equipment_id: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 1, 8, 1]}, value], %Telegram{} = telegram, opts) do
    %{telegram | electricity_delivered_1: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 1, 8, 2]}, value], %Telegram{} = telegram, opts) do
    %{telegram | electricity_delivered_2: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 2, 8, 1]}, value], %Telegram{} = telegram, opts) do
    %{telegram | electricity_returned_1: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 2, 8, 2]}, value], %Telegram{} = telegram, opts) do
    %{telegram | electricity_returned_2: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [0, 0, 96, 14, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | electricity_tariff_indicator: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 1, 7, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | electricity_currently_delivered: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 2, 7, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | electricity_currently_returned: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [0, 0, 96, 7, 21]}, value], %Telegram{} = telegram, opts) do
    %{telegram | power_failures_count: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [0, 0, 96, 7, 9]}, value], %Telegram{} = telegram, opts) do
    %{telegram | power_failures_long_count: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 99, 97, 0]}, value], %Telegram{} = telegram, opts) do
    # @TODO Raise error if events do not match count.
    [_count, {:obis, [0, 0, 96, 7, 19]} | events] = value

    events =
      events
      |> Enum.map(&extract_value(&1, opts))
      |> Enum.chunk_every(2)

    %{telegram | power_failures_log: events}
  end

  defp attrs_from_object([{:obis, [1, 0, 32, 32, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | voltage_sags_l1_count: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 52, 32, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | voltage_sags_l2_count: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 72, 32, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | voltage_sags_l3_count: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 32, 36, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | voltage_swells_l1_count: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 52, 36, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | voltage_swells_l2_count: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 72, 36, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | voltage_swells_l3_count: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [0, 0, 17, 0, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | actual_threshold_electricity: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [0, 0, 96, 3, 10]}, value], %Telegram{} = telegram, opts) do
    %{telegram | actual_switch_position: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [0, 0, 96, 13, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | text_message: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [0, 0, 96, 13, 1]}, value], %Telegram{} = telegram, opts) do
    %{telegram | text_message_code: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 31, 7, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | phase_power_current_l1: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 51, 7, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | phase_power_current_l2: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 71, 7, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | phase_power_current_l3: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 21, 7, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | currently_delivered_l1: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 41, 7, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | currently_delivered_l2: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 61, 7, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | currently_delivered_l3: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 22, 7, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | currently_returned_l1: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 42, 7, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | currently_returned_l2: extract_value(value, opts)}
  end

  defp attrs_from_object([{:obis, [1, 0, 62, 7, 0]}, value], %Telegram{} = telegram, opts) do
    %{telegram | currently_returned_l3: extract_value(value, opts)}
  end

  defp attrs_from_object(
         [{:obis, [0, _channel, 24, 1, 0]}, value],
         %MBusDevice{} = mbus_device,
         opts
       ) do
    %{mbus_device | device_type: extract_value(value, opts)}
  end

  defp attrs_from_object(
         [{:obis, [0, _channel, 96, 1, 0]}, value],
         %MBusDevice{} = mbus_device,
         opts
       ) do
    %{mbus_device | equipment_id: extract_value(value, opts)}
  end

  defp attrs_from_object(
         [{:obis, [0, _channel, 24, 2, 1]}, value],
         %MBusDevice{} = mbus_device,
         opts
       ) do
    [measured_at, value] = value

    %{
      mbus_device
      | last_reading_measured_at: extract_value(measured_at, opts),
        last_reading_value: extract_value(value, opts)
    }
  end

  defp attrs_from_object(
         [{:obis, [0, 1, 24, 4, 0]}, value],
         %MBusDevice{} = mbus_device,
         opts
       ) do
    %{mbus_device | valve_position: extract_value(value, opts)}
  end

  defp attrs_from_object(
         [{:obis, [0, 1, 24, 3, 0]}, value],
         %MBusDevice{} = mbus_device,
         opts
       ) do
    [{:string, timestamp}, _, _, _, {:obis, [0, 1, 24, 2, 1]}, {:string, unit}, {:string, value}] =
      value

    measurement = %Measurement{unit: unit, value: extract_value({:float, value}, opts)}
    timestamp = extract_value({:timestamp, timestamp}, opts)

    %{mbus_device | last_reading_value: measurement, last_reading_measured_at: timestamp}
  end

  # Skip any unsupported telegram objects.
  defp attrs_from_object(_object, telegram, _opts), do: telegram

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

  defp group_by_mbus_channels([{:obis, [0, channel, 24, 1, 0]}, _value]), do: channel
  defp group_by_mbus_channels([{:obis, [0, channel, 96, 1, 0]}, _value]), do: channel
  defp group_by_mbus_channels([{:obis, [0, channel, 24, 2, 1]}, _value]), do: channel
  # Legacy valve position (prior v4.2).
  defp group_by_mbus_channels([{:obis, [0, 1, 24, 4, 0]}, _value]), do: 1
  # Legacy last gasmeter reading (prior v4.2).
  defp group_by_mbus_channels([{:obis, [0, 1, 24, 3, 0]}, _value]), do: 1
  defp group_by_mbus_channels(_), do: 0
end
