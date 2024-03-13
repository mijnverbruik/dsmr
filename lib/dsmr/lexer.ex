defmodule DSMR.Lexer do
  import NimbleParsec

  eol = ascii_char([?\r]) |> ascii_char([?\n])

  any_char = ascii_char([])

  digit = ascii_string([?0..?9], min: 1)

  alnum = ascii_string([?a..?z, ?A..?Z, ?0..?9], min: 1)

  lparen_token =
    ascii_char([?(])
    |> post_traverse({:atom_token, []})

  rparen_token =
    ascii_char([?)])
    |> post_traverse({:atom_token, []})

  string_value =
    alnum
    |> unwrap_and_tag(:string)

  float_value =
    digit
    |> ascii_char([?.])
    |> concat(digit)
    |> post_traverse({:float_value_token, []})

  int_value =
    integer(min: 1)
    |> unwrap_and_tag(:int)

  timestamp_value =
    times(integer(2), 6)
    |> reduce(ascii_char([?S, ?W]), {List, :to_string, []})
    |> tag(:timestamp)

  measurement_value =
    choice([float_value, int_value])
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
    |> repeat_while(
      lparen_token
      |> optional(
        choice([
          timestamp_value,
          obis_value,
          measurement_value,
          float_value,
          string_value
        ])
      )
      |> concat(rparen_token)
      |> optional(ignore(eol)),
      {:not_end_of_line, []}
    )

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
    |> repeat(object_value)
    |> concat(footer_value)
    |> ignore(eol)

  @spec tokenize(binary(), keyword()) ::
          {:ok, [any()]}
          | {:error, binary(), {integer(), non_neg_integer()}}
  def tokenize(input, options \\ []) do
    tokenize_opts = [context: %{floats: Keyword.get(options, :floats, :native)}]

    case do_tokenize(input, tokenize_opts) do
      {:ok, tokens, "", _, _, _} ->
        {:ok, tokens}

      {:error, reason, rest, _, _, _} ->
        {:error, reason, rest}
    end
  end

  defparsecp(:do_tokenize, telegram, inline: true)

  defp atom_token(rest, chars, context, _line, _offset) do
    value = chars |> Enum.reverse()
    token_atom = value |> List.to_atom()

    {rest, [{token_atom}], context}
  end

  defp float_value_token(rest, chars, %{floats: :native} = context, _line, _offset) do
    string = chars |> Enum.reverse() |> List.to_string()
    {rest, [{:float, :erlang.binary_to_float(string)}], context}
  end

  defp float_value_token(rest, chars, %{floats: :decimals} = context, _line, _offset) do
    string = chars |> Enum.reverse() |> List.to_string()
    # silence xref warning
    decimal = Decimal

    try do
      {rest, [{:float, decimal.new(string)}], context}
    rescue
      Decimal.Error -> {:error, "invalid float"}
    end
  end

  defp not_end_of_line(<<?\r, ?\n, _::binary>>, context, _, _), do: {:halt, context}
  defp not_end_of_line(_, context, _, _), do: {:cont, context}
end
