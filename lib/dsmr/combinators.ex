defmodule DSMR.Combinators do
  @moduledoc false

  import NimbleParsec

  alias DSMR.{Measurement, Timestamp}

  def eol, do: ascii_char([?\r]) |> ascii_char([?\n])

  def any_char, do: ascii_char([])

  def digit, do: ascii_string([?0..?9], min: 1)

  def alnum, do: ascii_string([?a..?z, ?A..?Z, ?0..?9], min: 1)

  def string_value do
    alnum()
    |> unwrap_and_tag(:string)
  end

  def float_value do
    digit()
    |> ascii_char([?.])
    |> concat(digit())
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:float)
  end

  def int_value do
    integer(min: 1)
    |> unwrap_and_tag(:int)
  end

  def timestamp_value do
    times(integer(2), 6)
    |> reduce(ascii_char([?S, ?W]), {List, :to_string, []})
    |> tag(:timestamp)
  end

  def measurement_value do
    choice([float_value(), int_value()])
    |> post_traverse({:value_token, []})
    |> ignore(ascii_char([?*]))
    |> concat(alnum())
    |> tag(:measurement)
  end

  def obis_value do
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
  end

  def object_value do
    obis_value()
    |> concat(
      repeat_while(
        ignore(ascii_char([?(]))
        |> optional(
          choice([
            timestamp_value(),
            obis_value(),
            measurement_value(),
            float_value(),
            string_value()
          ])
          |> post_traverse({:value_token, []})
        )
        |> ignore(ascii_char([?)]))
        |> optional(ignore(eol())),
        {:not_end_of_line, []}
      )
      |> tag(:value)
    )
    |> post_traverse({:object_token, []})
  end

  def header_value do
    ignore(ascii_char([?/]))
    |> repeat_while(any_char(), {:not_end_of_line, []})
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:header)
  end

  def footer_value do
    ignore(ascii_char([?!]))
    |> repeat_while(any_char(), {:not_end_of_line, []})
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:footer)
  end

  def telegram do
    header_value()
    |> ignore(eol())
    |> ignore(eol())
    |> concat(
      repeat(object_value())
      |> tag(:objects)
    )
    |> concat(footer_value())
    |> ignore(eol())
  end

  def object_token(rest, [value, {:obis, obis}], context, _line, _offset) do
    value =
      case value do
        {:value, [value]} -> value
        {:value, []} -> nil
        {:value, values} -> values
      end

    {rest, [{obis, value}], context}
  end

  def value_token(rest, [{:float, value}], %{floats: :native} = context, _line, _offset) do
    {rest, [:erlang.binary_to_float(value)], context}
  end

  def value_token(rest, [{:float, value}], %{floats: :decimals} = context, _line, _offset) do
    # silence xref warning
    decimal = Decimal

    try do
      {rest, [decimal.new(value)], context}
    rescue
      Decimal.Error -> {:error, "invalid float"}
    end
  end

  def value_token(rest, [{:measurement, value}], context, _line, _offset) do
    [value, unit] = value
    {rest, [%Measurement{value: value, unit: unit}], context}
  end

  def value_token(rest, [{:timestamp, value}], context, _line, _offset) do
    [year, month, day, hour, minute, second, dst] = value

    # As the year is abbreviated, we need to normalize it as well.
    timestamp = NaiveDateTime.new!(2000 + year, month, day, hour, minute, second)

    {rest, [%Timestamp{value: timestamp, dst: dst}], context}
  end

  def value_token(rest, [{_token, value}], context, _line, _offset) do
    {rest, [value], context}
  end

  def not_end_of_line(<<?\r, ?\n, _::binary>>, context, _, _), do: {:halt, context}
  def not_end_of_line(_, context, _, _), do: {:cont, context}
end
