defmodule DSMR.Parser do
  @moduledoc false

  alias DSMR.{MBusDevice, Measurement, Telegram, Timestamp}

  # OBIS code -> field mapping for Telegram struct
  @telegram_obis_map %{
    [1, 3, 0, 2, 8] => :version,
    [0, 0, 1, 0, 0] => :measured_at,
    [0, 0, 96, 1, 1] => :equipment_id,
    [1, 0, 1, 8, 1] => :electricity_delivered_1,
    [1, 0, 1, 8, 2] => :electricity_delivered_2,
    [1, 0, 2, 8, 1] => :electricity_returned_1,
    [1, 0, 2, 8, 2] => :electricity_returned_2,
    [0, 0, 96, 14, 0] => :electricity_tariff_indicator,
    [1, 0, 1, 7, 0] => :electricity_currently_delivered,
    [1, 0, 2, 7, 0] => :electricity_currently_returned,
    [0, 0, 96, 7, 21] => :power_failures_count,
    [0, 0, 96, 7, 9] => :power_failures_long_count,
    [1, 0, 32, 32, 0] => :voltage_sags_l1_count,
    [1, 0, 52, 32, 0] => :voltage_sags_l2_count,
    [1, 0, 72, 32, 0] => :voltage_sags_l3_count,
    [1, 0, 32, 36, 0] => :voltage_swells_l1_count,
    [1, 0, 52, 36, 0] => :voltage_swells_l2_count,
    [1, 0, 72, 36, 0] => :voltage_swells_l3_count,
    [0, 0, 17, 0, 0] => :actual_threshold_electricity,
    [0, 0, 96, 3, 10] => :actual_switch_position,
    [0, 0, 96, 13, 0] => :text_message,
    [0, 0, 96, 13, 1] => :text_message_code,
    [1, 0, 31, 7, 0] => :phase_power_current_l1,
    [1, 0, 51, 7, 0] => :phase_power_current_l2,
    [1, 0, 71, 7, 0] => :phase_power_current_l3,
    [1, 0, 21, 7, 0] => :currently_delivered_l1,
    [1, 0, 41, 7, 0] => :currently_delivered_l2,
    [1, 0, 61, 7, 0] => :currently_delivered_l3,
    [1, 0, 22, 7, 0] => :currently_returned_l1,
    [1, 0, 42, 7, 0] => :currently_returned_l2,
    [1, 0, 62, 7, 0] => :currently_returned_l3
  }

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

  # Special case: power failures log with nested structure
  defp attrs_from_object([{:obis, [1, 0, 99, 97, 0]}, value], %Telegram{} = telegram, opts) do
    # @TODO Raise error if events do not match count.
    [_count, {:obis, [0, 0, 96, 7, 19]} | events] = value

    events =
      events
      |> Enum.map(&extract_value(&1, opts))
      |> Enum.chunk_every(2)

    %{telegram | power_failures_log: events}
  end

  # Generic OBIS handler for Telegram struct using lookup table
  defp attrs_from_object([{:obis, code}, value], %Telegram{} = telegram, opts) do
    case Map.get(@telegram_obis_map, code) do
      nil -> telegram
      field -> Map.put(telegram, field, extract_value(value, opts))
    end
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
