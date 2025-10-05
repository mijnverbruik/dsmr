defmodule DSMR.Telegram do
  @enforce_keys [:header, :checksum]
  defstruct [
    :header,
    :checksum,
    :version,
    :measured_at,
    :equipment_id,
    :electricity_delivered_1,
    :electricity_delivered_2,
    :electricity_returned_1,
    :electricity_returned_2,
    :electricity_tariff_indicator,
    :electricity_currently_delivered,
    :electricity_currently_returned,
    :power_failures_count,
    :power_failures_long_count,
    :power_failures_log,
    :voltage_sags_l1_count,
    :voltage_sags_l2_count,
    :voltage_sags_l3_count,
    :voltage_swells_l1_count,
    :voltage_swells_l2_count,
    :voltage_swells_l3_count,
    :actual_threshold_electricity,
    :actual_switch_position,
    :text_message,
    :text_message_code,
    :phase_power_current_l1,
    :phase_power_current_l2,
    :phase_power_current_l3,
    :currently_delivered_l1,
    :currently_delivered_l2,
    :currently_delivered_l3,
    :currently_returned_l1,
    :currently_returned_l2,
    :currently_returned_l3,
    :voltage_l1,
    :voltage_l2,
    :voltage_l3,
    mbus_devices: []
  ]

  @type obis_t() ::
          {non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer(),
           non_neg_integer()}

  @type value_t() ::
          String.t()
          | obis_t()
          | DSMR.Timestamp.t()
          | DSMR.Measurement.t()

  @type obj_t() :: {obis_t(), value_t() | [value_t()]}

  @type t() :: %__MODULE__{
          header: String.t(),
          checksum: String.t(),
          version: String.t(),
          measured_at: DSMR.Timestamp.t(),
          equipment_id: String.t(),
          electricity_delivered_1: DSMR.Measurement.t(),
          electricity_delivered_2: DSMR.Measurement.t(),
          electricity_returned_1: DSMR.Measurement.t(),
          electricity_returned_2: DSMR.Measurement.t(),
          electricity_tariff_indicator: String.t(),
          electricity_currently_delivered: DSMR.Measurement.t(),
          electricity_currently_returned: DSMR.Measurement.t(),
          power_failures_count: String.t(),
          power_failures_long_count: String.t(),
          power_failures_log: [{DSMR.Timestamp.t(), DSMR.Measurement.t()}],
          voltage_sags_l1_count: String.t(),
          voltage_sags_l2_count: String.t(),
          voltage_sags_l3_count: String.t(),
          voltage_swells_l1_count: String.t(),
          voltage_swells_l2_count: String.t(),
          voltage_swells_l3_count: String.t(),
          actual_threshold_electricity: DSMR.Measurement.t(),
          actual_switch_position: String.t(),
          text_message: String.t(),
          text_message_code: String.t(),
          phase_power_current_l1: DSMR.Measurement.t(),
          phase_power_current_l2: DSMR.Measurement.t(),
          phase_power_current_l3: DSMR.Measurement.t(),
          currently_delivered_l1: DSMR.Measurement.t(),
          currently_delivered_l2: DSMR.Measurement.t(),
          currently_delivered_l3: DSMR.Measurement.t(),
          currently_returned_l1: DSMR.Measurement.t(),
          currently_returned_l2: DSMR.Measurement.t(),
          currently_returned_l3: DSMR.Measurement.t(),
          voltage_l1: DSMR.Measurement.t(),
          voltage_l2: DSMR.Measurement.t(),
          voltage_l3: DSMR.Measurement.t(),
          mbus_devices: [DSMR.MBusDevice.t()]
        }

  alias DSMR.{Measurement, MBusDevice, OBIS, Timestamp}

  @doc """
  Converts a Telegram struct back to its string representation.

  ## Examples

      iex> telegram = %DSMR.Telegram{
      ...>   header: "ISk5\\\\2MT382-1000",
      ...>   checksum: "5106",
      ...>   version: "50"
      ...> }
      iex> DSMR.Telegram.to_string(telegram)
      "/ISk5\\\\2MT382-1000\\r\\n\\r\\n1-3:0.2.8(50)\\r\\n!5106\\r\\n"

  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = telegram) do
    lines = [
      "/#{telegram.header}",
      "",
      telegram_fields_to_lines(telegram),
      mbus_devices_to_lines(telegram.mbus_devices),
      "!#{telegram.checksum}"
    ]

    lines
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\r\n")
    |> Kernel.<>("\r\n")
  end

  defp telegram_fields_to_lines(telegram) do
    OBIS.field_order()
    |> Enum.map(fn field ->
      case field do
        :power_failures_log ->
          power_failures_log_to_line(Map.get(telegram, field))

        _ ->
          field_to_line(field, Map.get(telegram, field))
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp field_to_line(_field, nil), do: nil
  defp field_to_line(_field, ""), do: nil

  defp field_to_line(field, %Measurement{} = measurement) do
    case OBIS.get_obis(field) do
      nil -> nil
      obis -> "#{obis}(#{format_measurement(measurement)})"
    end
  end

  defp field_to_line(field, %Timestamp{} = timestamp) do
    case OBIS.get_obis(field) do
      nil -> nil
      obis -> "#{obis}(#{format_timestamp(timestamp)})"
    end
  end

  defp field_to_line(field, value) when is_binary(value) do
    case OBIS.get_obis(field) do
      nil -> nil
      obis -> "#{obis}(#{value})"
    end
  end

  defp power_failures_log_to_line(nil), do: nil
  defp power_failures_log_to_line([]), do: "1-0:99.97.0(0)(0-0:96.7.19)"

  defp power_failures_log_to_line(log) when is_list(log) do
    count = length(log)

    events =
      log
      |> Enum.map(fn [timestamp, duration] ->
        "(#{format_timestamp(timestamp)})(#{format_measurement(duration)})"
      end)
      |> Enum.join()

    "1-0:99.97.0(#{count})(0-0:96.7.19)#{events}"
  end

  defp mbus_devices_to_lines([]), do: []

  defp mbus_devices_to_lines(devices) do
    Enum.flat_map(devices, &mbus_device_to_lines/1)
  end

  defp mbus_device_to_lines(%MBusDevice{} = device) do
    [
      mbus_field_to_line(device.channel, "0-#{device.channel}:24.1.0", device.device_type),
      mbus_field_to_line(device.channel, "0-#{device.channel}:96.1.0", device.equipment_id),
      mbus_reading_to_line(device),
      mbus_field_to_line(device.channel, "0-#{device.channel}:24.4.0", device.valve_position)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp mbus_field_to_line(_channel, _obis, nil), do: nil
  defp mbus_field_to_line(_channel, _obis, ""), do: nil

  defp mbus_field_to_line(_channel, obis, value) when is_binary(value) do
    "#{obis}(#{value})"
  end

  defp mbus_reading_to_line(%MBusDevice{last_reading_measured_at: nil}), do: nil
  defp mbus_reading_to_line(%MBusDevice{last_reading_value: nil}), do: nil

  defp mbus_reading_to_line(%MBusDevice{
         channel: channel,
         last_reading_measured_at: timestamp,
         last_reading_value: measurement
       }) do
    "0-#{channel}:24.2.1(#{format_timestamp(timestamp)})(#{format_measurement(measurement)})"
  end

  defp format_measurement(%Measurement{value: value, unit: unit}) do
    formatted_value = format_number(value)
    "#{formatted_value}*#{unit}"
  end

  defp format_number(value) when is_float(value) do
    # Format with up to 3 decimal places, removing trailing zeros
    :erlang.float_to_binary(value, decimals: 3)
    |> String.replace(~r/\.?0+$/, "")
    |> pad_measurement()
  end

  defp format_number(%Decimal{} = value) do
    Decimal.to_string(value)
    |> pad_measurement()
  end

  defp format_number(value) when is_integer(value) do
    Integer.to_string(value)
    |> pad_measurement()
  end

  defp pad_measurement(str) do
    case String.split(str, ".") do
      [int] ->
        String.pad_leading(int, 6, "0")

      [int, dec] ->
        padded_int = String.pad_leading(int, 6, "0")
        "#{padded_int}.#{dec}"
    end
  end

  defp format_timestamp(%Timestamp{value: datetime, dst: dst}) do
    year = datetime.year - 2000
    month = datetime.month
    day = datetime.day
    hour = datetime.hour
    minute = datetime.minute
    second = datetime.second

    timestamp_str =
      "#{pad(year)}#{pad(month)}#{pad(day)}#{pad(hour)}#{pad(minute)}#{pad(second)}"

    if dst, do: "#{timestamp_str}#{dst}", else: timestamp_str
  end

  defp pad(value) do
    value |> Integer.to_string() |> String.pad_leading(2, "0")
  end
end
