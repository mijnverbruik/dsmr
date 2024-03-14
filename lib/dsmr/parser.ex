defmodule DSMR.Parser do
  @moduledoc false

  import NimbleParsec

  eol = ascii_char([?\r]) |> ascii_char([?\n])

  any_char = ascii_char([])

  digit = ascii_string([?0..?9], min: 1)

  alnum = ascii_string([?a..?z, ?A..?Z, ?0..?9], min: 1)

  lparen_token = ascii_char([?(])
  rparen_token = ascii_char([?)])

  string_value =
    alnum
    |> unwrap_and_tag(:string)

  float_value =
    digit
    |> ascii_char([?.])
    |> concat(digit)
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:float)

  int_value =
    integer(min: 1)
    |> unwrap_and_tag(:int)

  timestamp_value =
    times(integer(2), 6)
    |> reduce(ascii_char([?S, ?W]), {List, :to_string, []})
    |> tag(:timestamp)

  measurement_value =
    choice([float_value, int_value])
    |> post_traverse({:value_token, []})
    |> ignore(ascii_char([?*]))
    |> concat(alnum)
    |> tag(:measurement)

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

  object_value =
    obis_value
    |> concat(
      repeat_while(
        ignore(lparen_token)
        |> optional(
          choice([
            timestamp_value,
            obis_value,
            measurement_value,
            float_value,
            string_value
          ])
          |> post_traverse({:value_token, []})
        )
        |> ignore(rparen_token)
        |> optional(ignore(eol)),
        {:not_end_of_line, []}
      )
      |> tag(:value)
    )
    |> post_traverse({:object_token, []})

  header_value =
    ignore(ascii_char([?/]))
    |> repeat_while(any_char, {:not_end_of_line, []})
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:header)

  footer_value =
    ignore(ascii_char([?!]))
    |> repeat_while(any_char, {:not_end_of_line, []})
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:footer)

  telegram =
    header_value
    |> ignore(eol)
    |> ignore(eol)
    |> concat(
      repeat(object_value)
      |> tag(:objects)
    )
    |> concat(footer_value)
    |> ignore(eol)

  @spec parse(binary(), keyword()) ::
          {:ok, binary(), [any()], binary()}
          | {:error, binary(), {integer(), non_neg_integer()}}
  def parse(input, options \\ []) do
    tokenize_opts = [context: %{floats: Keyword.get(options, :floats, :native)}]

    case do_parse(input, tokenize_opts) do
      {:ok, tokens, "", _, _, _} ->
        [{:header, header}, {:objects, data}, {:footer, checksum}] = tokens
        {:ok, header, data, checksum}

      {:error, reason, rest, _, _, _} ->
        {:error, reason, rest}
    end
  end

  defparsecp(:do_parse, telegram, inline: true)

  defp object_token(rest, [value, {:obis, obis}], context, _line, _offset) do
    value =
      case value do
        {:value, [value]} -> value
        {:value, []} -> nil
        {:value, values} -> values
      end

    {rest, [{obis, value}], context}
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
    {rest, [%{value: value, unit: unit}], context}
  end

  defp value_token(rest, [{:timestamp, value}], context, _line, _offset) do
    [year, month, day, hour, minute, second, dst] = value

    # As the year is abbreviated, we need to normalize it as well.
    timestamp = NaiveDateTime.new!(2000 + year, month, day, hour, minute, second)

    {rest, [{timestamp, dst}], context}
  end

  defp value_token(rest, [{_token, value}], context, _line, _offset) do
    {rest, [value], context}
  end

  defp not_end_of_line(<<?\r, ?\n, _::binary>>, context, _, _), do: {:halt, context}
  defp not_end_of_line(_, context, _, _), do: {:cont, context}
end
