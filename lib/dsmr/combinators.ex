defmodule DSMR.Combinators do
  @moduledoc false

  import NimbleParsec

  def lparen_token, do: ascii_char([?(])
  def rparen_token, do: ascii_char([?)])

  def obis_value(combinator \\ empty()) do
    combinator
    |> integer(min: 1)
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

  def object(combinator \\ empty(), obis_str, attribute_combinator) do
    combinator
    |> lookahead(string(obis_str))
    |> obis_value()
    |> concat(attribute_combinator)
    |> post_traverse({:object_token, []})
  end

  def attribute(combinator \\ empty(), value_combinator) do
    combinator
    |> concat(value_combinator)
    |> wrap_with_parens()
    |> post_traverse({:attribute_token, []})
  end

  def optional_attribute(combinator \\ empty(), attribute_combinator) do
    combinator
    |> choice([
      attribute_combinator,
      empty()
    ])
    |> attribute()
  end

  def value(combinator \\ empty(), value_combinator) do
    combinator
    |> concat(value_combinator)
    |> post_traverse({:value_token, []})
  end

  def wrap_with_parens(combinator \\ empty(), to_wrap) do
    combinator
    |> ignore(lparen_token())
    |> concat(to_wrap)
    |> ignore(rparen_token())
  end
end
