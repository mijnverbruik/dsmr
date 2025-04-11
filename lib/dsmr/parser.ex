defmodule DSMR.Parser do
  @moduledoc false

  import NimbleParsec
  import DSMR.Combinators

  alias DSMR.{Measurement, Telegram, Timestamp}

  eol = ascii_char([?\r]) |> ascii_char([?\n])

  any_char = ascii_char([])

  digit = ascii_string([?0..?9], min: 1)

  alnum = ascii_string([?a..?z, ?A..?Z, ?0..?9], min: 1)

  float_value =
    digit
    |> ascii_char([?.])
    |> concat(digit)
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:float)
    |> value()

  int_value =
    integer(min: 1)
    |> unwrap_and_tag(:int)
    |> value()

  string_value =
    alnum
    |> unwrap_and_tag(:string)
    |> value()

  timestamp_value =
    times(integer(2), 6)
    |> reduce(ascii_char([?S, ?W]), {List, :to_string, []})
    |> tag(:timestamp)
    |> value()

  measurement_value =
    choice([float_value, int_value])
    |> ignore(ascii_char([?*]))
    |> concat(alnum)
    |> tag(:measurement)
    |> value()

  legacy_measurement_value =
    string_value
    |> wrap_with_parens()
    |> ignore(eol)
    |> concat(choice([float_value, int_value]) |> wrap_with_parens())
    |> tag(:legacy_measurement)
    |> value()

  obis_value =
    integer(min: 1)
    |> ignore(ascii_char([?-]))
    |> integer(min: 1)
    |> ignore(ascii_char([?:]))
    |> integer(min: 1)
    |> ignore(ascii_char([?.]))
    |> integer(min: 1)
    |> ignore(ascii_char([?.]))
    |> integer(min: 1)
    |> tag(:obis)
    |> value()

  event_log_attribute =
    attribute(int_value)
    |> concat(attribute(obis_value))
    |> concat(
      repeat(
        concat(
          attribute(timestamp_value),
          attribute(measurement_value)
        )
      )
    )
    |> post_traverse({:attribute_token, []})

  mbus_reading_attribute =
    repeat(
      concat(
        attribute(timestamp_value),
        attribute(measurement_value)
      )
    )
    |> post_traverse({:attribute_token, []})

  legacy_gas_reading_attribute =
    attribute(string_value)
    |> concat(attribute(string_value))
    |> concat(attribute(string_value))
    |> concat(attribute(string_value))
    |> concat(attribute(obis_value))
    |> concat(legacy_measurement_value)
    |> post_traverse({:attribute_token, []})

  data =
    choice(
      [
        object("1-3:0.2.8", attribute(string_value)),
        object("0-0:1.0.0", attribute(timestamp_value)),
        object("0-0:96.1.1", attribute(string_value)),
        object("1-0:1.8.1", attribute(measurement_value)),
        object("1-0:1.8.2", attribute(measurement_value)),
        object("1-0:2.8.1", attribute(measurement_value)),
        object("1-0:2.8.2", attribute(measurement_value)),
        object("0-0:96.14.0", attribute(string_value)),
        object("1-0:1.7.0", attribute(measurement_value)),
        object("1-0:2.7.0", attribute(measurement_value)),
        object("0-0:96.7.21", attribute(string_value)),
        object("0-0:96.7.9", attribute(string_value)),
        object("1-0:99.97.0", event_log_attribute),
        object("1-0:32.32.0", attribute(string_value)),
        object("1-0:52.32.0", attribute(string_value)),
        object("1-0:72.32.0", attribute(string_value)),
        object("1-0:32.36.0", attribute(string_value)),
        object("1-0:52.36.0", attribute(string_value)),
        object("1-0:72.36.0", attribute(string_value)),
        object("1-0:32.7.0", attribute(measurement_value)),
        object("1-0:52.7.0", attribute(measurement_value)),
        object("1-0:72.7.0", attribute(measurement_value)),
        object("0-0:96.13.1", optional_attribute(string_value)),
        object("0-0:96.13.0", optional_attribute(string_value)),
        object("1-0:31.7.0", attribute(measurement_value)),
        object("1-0:51.7.0", attribute(measurement_value)),
        object("1-0:71.7.0", attribute(measurement_value)),
        object("1-0:21.7.0", attribute(measurement_value)),
        object("1-0:22.7.0", attribute(measurement_value)),
        object("1-0:41.7.0", attribute(measurement_value)),
        object("1-0:42.7.0", attribute(measurement_value)),
        object("1-0:61.7.0", attribute(measurement_value)),
        object("1-0:62.7.0", attribute(measurement_value)),

        # actual threshold electricity (removed in v4.2.2)
        object("0-0:17.0.0", attribute(measurement_value)),
        # actual switch position (removed in v4.2.2)
        object("0-0:96.3.10", attribute(string_value)),
        # gas meter reading (removed in v4.2.2)
        object("0-1:24.3.0", legacy_gas_reading_attribute),
        # mbus valve position (removed in v4.2.2)
        object("0-1:24.4.0", attribute(string_value))
      ] ++
        Enum.flat_map(1..4, fn i ->
          [
            object("0-#{i}:24.1.0", attribute(string_value)),
            object("0-#{i}:96.1.0", optional_attribute(string_value)),
            object("0-#{i}:24.2.1", mbus_reading_attribute)
          ]
        end)
    )
    |> ignore(eol)

  header =
    ignore(ascii_char([?/]))
    |> repeat_while(any_char, {:not_end_of_line, []})
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:header)

  footer =
    ignore(ascii_char([?!]))
    |> repeat_while(any_char, {:not_end_of_line, []})
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:footer)

  telegram =
    header
    |> ignore(eol)
    |> ignore(eol)
    |> concat(
      repeat(data)
      |> tag(:data)
    )
    |> concat(footer)
    |> ignore(eol)

  @spec parse(binary(), keyword()) ::
          {:ok, Telegram.t()} | {:error, binary(), binary()}
  def parse(input, options) do
    tokenize_opts = [context: %{floats: Keyword.get(options, :floats, :native)}]

    case do_parse(input, tokenize_opts) do
      {:ok, tokens, "", _, _, _} ->
        [{:header, header}, {:data, data}, {:footer, checksum}] = tokens
        {:ok, %Telegram{header: header, data: data, checksum: checksum}}

      {:error, reason, rest, _, _, _} ->
        {:error, reason, rest}
    end
  end

  @spec do_parse(binary()) ::
          {:ok, [any()], binary(), map(), {pos_integer(), pos_integer()}, pos_integer()}
          | {:error, String.t(), String.t(), map(), {non_neg_integer(), non_neg_integer()},
             non_neg_integer()}
  defparsecp(:do_parse, telegram, inline: true)

  defp object_token(rest, [attribute, {:obis, obis}], context, _line, _offset) do
    {rest, [{obis, attribute}], context}
  end

  defp attribute_token(rest, [attribute], context, _line, _offset) do
    {rest, [attribute], context}
  end

  defp attribute_token(rest, [], context, _line, _offset) do
    {rest, [nil], context}
  end

  defp attribute_token(rest, attributes, context, _line, _offset) do
    {rest, [Enum.reverse(attributes)], context}
  end

  defp value_token(rest, [{:float, value}], %{floats: :native} = context, _line, _offset) do
    {rest, [:erlang.binary_to_float(value)], context}
  end

  defp value_token(rest, [{:float, value}], %{floats: :decimals} = context, _line, _offset) do
    # silence xref warning
    decimal = Decimal

    try do
      {rest, [decimal.new(value)], context}
    rescue
      Decimal.Error -> {:error, "invalid float"}
    end
  end

  defp value_token(rest, [{:measurement, value}], context, _line, _offset) do
    [value, unit] = value
    {rest, [%Measurement{value: value, unit: unit}], context}
  end

  defp value_token(rest, [{:legacy_measurement, value}], context, _line, _offset) do
    [unit, value] = value
    {rest, [%Measurement{value: value, unit: unit}], context}
  end

  defp value_token(rest, [{:timestamp, value}], context, _line, _offset) do
    [year, month, day, hour, minute, second, dst] = value

    # As the year is abbreviated, we need to normalize it as well.
    timestamp = NaiveDateTime.new!(2000 + year, month, day, hour, minute, second)

    {rest, [%Timestamp{value: timestamp, dst: dst}], context}
  end

  defp value_token(rest, [{_token, value}], context, _line, _offset) do
    {rest, [value], context}
  end

  defp not_end_of_line(<<?\r, ?\n, _::binary>>, context, _, _), do: {:halt, context}
  defp not_end_of_line(_, context, _, _), do: {:cont, context}
end
