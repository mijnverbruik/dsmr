defmodule DSMR.Parser do
  @moduledoc false

  alias DSMR.{MBusDevice, Measurement, Telegram, Timestamp}

  # Fields that must contain a timestamp. The lexer only produces timestamp
  # tokens for values with a DST marker (12 digits + W/S); anything else that
  # lands in these fields (e.g. a bare 12-digit value) is a spec violation.
  @timestamp_fields for {field, {_obis, :timestamp}} <- DSMR.OBIS.field_definitions(), do: field

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
  catch
    # Input errors detected deep inside value extraction are thrown so they
    # don't have to be threaded through every extract_value/2 clause.
    {:dsmr_parse_error, %DSMR.ParseError{} = error} -> {:error, error}
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

        {telegram_fields, other_fields} =
          data
          |> Enum.split_with(fn
            {:telegram_field, _, _} -> true
            _ -> false
          end)

        {mbus_fields, unknown_fields} =
          other_fields
          |> Enum.split_with(fn
            {:mbus_field, _, _, _} -> true
            _ -> false
          end)

        # MBus device fields are grouped by channel
        grouped_mbus_fields =
          mbus_fields
          |> Enum.group_by(fn {:mbus_field, channel, _, _} -> channel end)
          |> Enum.sort_by(fn {channel, _} -> channel end)

        with {:ok, telegram} <- process_telegram_fields(telegram, telegram_fields, opts),
             {:ok, mbus_devices} <- process_mbus_devices(grouped_mbus_fields, opts) do
          # Process unknown OBIS codes
          unknown =
            unknown_fields
            |> Enum.map(fn {:unknown_obis, code, attrs} ->
              {List.to_tuple(code), extract_value(attrs, opts)}
            end)

          {:ok, %{telegram | mbus_devices: mbus_devices, unknown_fields: unknown}}
        end

      {:error, error_tuple} ->
        {:error, error_tuple}
    end
  end

  defp process_telegram_fields(telegram, fields, opts) do
    Enum.reduce_while(fields, {:ok, telegram}, fn {:telegram_field, field, attrs}, {:ok, acc} ->
      case process_telegram_field(acc, field, attrs, opts) do
        {:ok, telegram} -> {:cont, {:ok, telegram}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  # Process telegram field - now field name comes from parser
  defp process_telegram_field(telegram, :power_failures_log, value, opts) do
    # Special case: power failures log with nested structure
    with [{:string, count_str}, {:obis, {[0, 0, 96, 7, 19], _}} | events] <- value,
         {count, ""} <- Integer.parse(count_str) do
      # Each event consists of 2 elements (timestamp and duration)
      actual_count = div(length(events), 2)

      if actual_count == count do
        events =
          events
          |> Enum.map(&extract_value(&1, opts))
          |> Enum.chunk_every(2)

        {:ok, %{telegram | power_failures_log: events}}
      else
        {:error,
         %DSMR.ParseError{
           message:
             "power failures log count mismatch: expected #{count} events, got #{actual_count}"
         }}
      end
    else
      _ -> {:error, %DSMR.ParseError{message: "malformed power failures log"}}
    end
  end

  defp process_telegram_field(telegram, field, value, opts) when field in @timestamp_fields do
    case extract_value(value, opts) do
      %Timestamp{} = timestamp ->
        {:ok, Map.put(telegram, field, timestamp)}

      _ ->
        {:error, %DSMR.ParseError{message: "invalid timestamp for #{field}: missing DST marker"}}
    end
  end

  defp process_telegram_field(telegram, field, value, opts) do
    {:ok, Map.put(telegram, field, extract_value(value, opts))}
  end

  defp process_mbus_devices(grouped_fields, opts) do
    grouped_fields
    |> Enum.reduce_while({:ok, []}, fn {channel, fields}, {:ok, acc} ->
      case process_mbus_device(channel, fields, opts) do
        {:ok, device} -> {:cont, {:ok, [device | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, devices} -> {:ok, Enum.reverse(devices)}
      {:error, _} = error -> error
    end
  end

  # Process MBus device from grouped fields
  defp process_mbus_device(channel, fields, opts) do
    Enum.reduce_while(fields, {:ok, %MBusDevice{channel: channel}}, fn field, {:ok, device} ->
      case process_mbus_field(field, device, opts) do
        {:ok, device} -> {:cont, {:ok, device}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp process_mbus_field({:mbus_field, _, :device_type, attrs}, device, opts) do
    {:ok, %{device | device_type: extract_value(attrs, opts)}}
  end

  defp process_mbus_field({:mbus_field, _, :equipment_id, attrs}, device, opts) do
    {:ok, %{device | equipment_id: extract_value(attrs, opts)}}
  end

  defp process_mbus_field({:mbus_field, channel, :last_reading, attrs}, device, opts) do
    with [measured_at, value] <- attrs,
         %Timestamp{} = timestamp <- extract_mbus_timestamp(measured_at, opts) do
      {:ok,
       %{
         device
         | last_reading_measured_at: timestamp,
           last_reading_value: extract_value(value, opts)
       }}
    else
      _ ->
        {:error, %DSMR.ParseError{message: "malformed M-Bus reading (0-#{channel}:24.2.1)"}}
    end
  end

  defp process_mbus_field({:mbus_field, _, :valve_position, attrs}, device, opts) do
    {:ok, %{device | valve_position: extract_value(attrs, opts)}}
  end

  # Legacy (DSMR 2.x) gas readings spread the reading over several attributes:
  # (timestamp)(status)(interval)(count)(reference obis)(unit)(value)
  defp process_mbus_field({:mbus_field, channel, :legacy_gas_reading, attrs}, device, opts) do
    case attrs do
      [
        {:string, timestamp},
        _status,
        _interval,
        _count,
        {:obis, {[0, ^channel, 24, 2, 1], _}},
        {:string, unit},
        {:string, value}
      ] ->
        measurement = %Measurement{
          unit: unit,
          value: extract_value({:float, value}, opts),
          raw: value
        }

        timestamp = extract_value({:timestamp, timestamp}, opts)

        {:ok, %{device | last_reading_value: measurement, last_reading_measured_at: timestamp}}

      _ ->
        {:error, %DSMR.ParseError{message: "malformed legacy gas reading (0-#{channel}:24.3.0)"}}
    end
  end

  # M-Bus readings converted from legacy meters (DSMR 2.2/3.0) carry a
  # timestamp without a DST marker; parse those into a Timestamp with a nil
  # dst instead of leaving them as plain strings.
  defp extract_mbus_timestamp({:string, <<_::binary-size(12)>> = value}, opts) do
    extract_value({:timestamp, value}, opts)
  end

  defp extract_mbus_timestamp(attr, opts), do: extract_value(attr, opts)

  defp extract_value([value], opts), do: extract_value(value, opts)
  defp extract_value(nil, _opts), do: nil

  defp extract_value({:measurement, {value, unit}}, opts) do
    {_token, raw} = value
    processed_value = extract_value(value, opts)
    %Measurement{unit: unit, value: processed_value, raw: raw}
  end

  defp extract_value({:timestamp, {value, dst}}, _opts) when is_binary(value) do
    with <<year::binary-2, month::binary-2, day::binary-2, hour::binary-2, minute::binary-2,
           second::binary-2>> <- value,
         [{year, ""}, {month, ""}, {day, ""}, {hour, ""}, {minute, ""}, {second, ""}] <-
           Enum.map([year, month, day, hour, minute, second], &Integer.parse/1),
         {:ok, timestamp} <- NaiveDateTime.new(2000 + year, month, day, hour, minute, second) do
      %Timestamp{value: timestamp, dst: dst}
    else
      _ ->
        throw({:dsmr_parse_error, %DSMR.ParseError{message: "invalid timestamp #{value}#{dst}"}})
    end
  end

  defp extract_value({:timestamp, value}, opts) when is_binary(value) do
    extract_value({:timestamp, {value, nil}}, opts)
  end

  defp extract_value({:float, value}, %{floats: :native} = _opts) do
    :erlang.binary_to_float(value)
  end

  if Code.ensure_loaded?(Decimal) do
    defp extract_value({:float, value}, %{floats: :decimals} = _opts) do
      Decimal.new(value)
    end
  else
    defp extract_value({:float, _value}, %{floats: :decimals} = _opts) do
      raise ArgumentError, "Decimal dependency is required when using floats: :decimals"
    end
  end

  defp extract_value({:int, value}, _opts) do
    :erlang.binary_to_integer(value)
  end

  defp extract_value({_token, value}, _opts) do
    value
  end
end
