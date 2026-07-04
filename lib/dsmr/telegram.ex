defmodule DSMR.Telegram do
  @moduledoc """
  A parsed DSMR telegram.

  A telegram contains the values broadcast by a smart meter at a point in time.
  Different DSMR versions expose different fields, so most fields are optional
  and remain `nil` when the input does not contain the corresponding OBIS code.

  Unknown OBIS codes are preserved in `unknown_fields` instead of being rejected.
  This keeps parsing tolerant of regional extensions and meter-specific fields.
  """

  alias DSMR.{Measurement, MBusDevice, OBIS, Timestamp}

  # The struct and its typespec are derived from DSMR.OBIS.field_definitions/0,
  # the single source of truth for telegram fields and their value types.
  @obis_field_definitions OBIS.field_definitions()

  @enforce_keys [:header, :checksum]
  defstruct [:header, :checksum] ++
              Keyword.keys(@obis_field_definitions) ++
              [mbus_devices: [], unknown_fields: []]

  @type obis_t() ::
          {non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer(),
           non_neg_integer()}

  @type maybe(type) :: type | nil

  @type value_t() ::
          String.t()
          | integer()
          | float()
          | Decimal.t()
          | obis_t()
          | DSMR.Timestamp.t()
          | DSMR.Measurement.t()
          | nil

  @type obj_t() :: {obis_t(), value_t() | [value_t()]}

  @type unknown_field_t() :: {obis_t(), value_t() | [value_t()]}

  @type power_failure_event_t() :: [DSMR.Timestamp.t() | DSMR.Measurement.t()]

  obis_field_specs =
    Enum.map(@obis_field_definitions, fn {field, {_obis, type}} ->
      spec =
        case type do
          :string -> quote(do: maybe(String.t()))
          :timestamp -> quote(do: maybe(DSMR.Timestamp.t()))
          :measurement -> quote(do: maybe(DSMR.Measurement.t()))
          :power_failures_log -> quote(do: maybe([power_failure_event_t()]))
        end

      {field, spec}
    end)

  telegram_specs =
    [header: quote(do: String.t()), checksum: quote(do: String.t())] ++
      obis_field_specs ++
      [
        mbus_devices: quote(do: [DSMR.MBusDevice.t()]),
        unknown_fields: quote(do: [unknown_field_t()])
      ]

  Code.eval_quoted(
    quote do
      @type t() :: %__MODULE__{unquote_splicing(telegram_specs)}
    end,
    [],
    __ENV__
  )

  @doc """
  Converts a Telegram struct back to its string representation.

  Fields with `nil` or empty string values are omitted.

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
      unknown_fields_to_lines(telegram.unknown_fields),
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

  # Measurements parsed from a telegram carry the exact original text in
  # `raw`; using it keeps serialization byte-for-byte lossless. Hand-built
  # measurements fall back to formatting the numeric value.
  defp format_measurement(%Measurement{raw: raw, unit: unit}) when is_binary(raw) do
    "#{raw}*#{unit}"
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

  if Code.ensure_loaded?(Decimal) do
    defp format_number(%Decimal{} = value) do
      Decimal.to_string(value)
      |> pad_measurement()
    end
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

  defp unknown_fields_to_lines([]), do: []

  defp unknown_fields_to_lines(fields) do
    Enum.map(fields, fn {code, values} ->
      obis = format_obis(code)
      attrs = format_unknown_values(values)
      "#{obis}#{attrs}"
    end)
  end

  defp format_obis({a, b, c, d, e}) do
    "#{a}-#{b}:#{c}.#{d}.#{e}"
  end

  defp format_unknown_values(values) when is_list(values) do
    values
    |> Enum.map(&format_unknown_value/1)
    |> Enum.join()
  end

  defp format_unknown_values(value) do
    format_unknown_value(value)
  end

  defp format_unknown_value(%Measurement{} = measurement) do
    "(#{format_measurement(measurement)})"
  end

  defp format_unknown_value(%Timestamp{} = timestamp) do
    "(#{format_timestamp(timestamp)})"
  end

  defp format_unknown_value({:obis, {a, b, c, d, e}}) do
    "(#{a}-#{b}:#{c}.#{d}.#{e})"
  end

  defp format_unknown_value(value) when is_binary(value) do
    "(#{value})"
  end

  defp format_unknown_value(value) when is_number(value) do
    "(#{value})"
  end

  defp format_unknown_value(nil) do
    "()"
  end
end
