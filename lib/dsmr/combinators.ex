defmodule DSMR.Combinators do
  @moduledoc false

  import NimbleParsec

  @separator [?\r, ?\n]
  def separator do
    empty()
    |> utf8_char([Enum.at(@separator, 0)])
    |> utf8_char([Enum.at(@separator, 1)])
    |> label("separator")
  end

  @left_parens [?(]
  def left_paren do
    utf8_char(@left_parens)
    |> label("left parenthesis")
  end

  @right_parens [?)]
  def right_paren do
    utf8_char(@right_parens)
    |> label("right parenthesis")
  end

  @decimal_places [?.]
  def decimal_place do
    utf8_char(@decimal_places)
    |> label("decimal place character")
  end

  @unit_places [?*]
  def unit_place do
    utf8_char(@unit_places)
    |> label("unit place character")
  end

  @digits [?0..?9]
  def digits do
    ascii_char(@digits)
    |> label("digits")
  end

  @letters [?a..?z, ?A..?Z]
  def letters do
    ascii_char(@letters)
    |> label("letters")
  end

  def obis_digit(combinator \\ empty()) do
    combinator
    |> concat(
      digits()
      |> times(min: 1)
      |> reduce({List, :to_integer, []})
    )
  end

  def obis do
    obis_digit()
    |> ignore(utf8_char([?-]))
    |> obis_digit()
    |> ignore(utf8_char([?:]))
    |> obis_digit()
    |> ignore(utf8_char([?.]))
    |> obis_digit()
    |> ignore(utf8_char([?.]))
    |> obis_digit()
    |> tag(:obis)
    |> label("obis")
  end

  @invalid_chars @separator ++
                   @decimal_places ++
                   @unit_places ++
                   @left_parens ++
                   @right_parens

  @unit Enum.map(@invalid_chars, fn s -> {:not, s} end)
  def unit do
    ignore(unit_place())
    |> times(utf8_char(@unit), min: 1)
    |> reduce({List, :to_string, []})
    |> label("unit")
  end

  def int do
    times(digits(), min: 1)
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:integer)
  end

  def float do
    times(digits(), min: 1)
    |> concat(decimal_place() |> times(digits(), min: 1))
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:float)
  end

  def number do
    choice([float(), int()])
    |> lookahead_not(letters())
    |> label("number")
    |> optional(unit() |> unwrap_and_tag(:unit))
  end

  def text do
    choice([digits(), letters()])
    |> repeat()
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:text)
    |> label("text")
  end

  def timestamp do
    digits()
    |> times(12)
    |> utf8_char([?S, ?W])
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:timestamp)
    |> label("timestamp")
  end

  def value do
    ignore(left_paren())
    |> choice([timestamp(), obis(), number(), text()])
    |> ignore(right_paren())
    |> map(:format_value)
    |> label("value")
  end

  def cosem do
    optional(obis())
    |> times(
      value()
      |> optional(separator() |> ignore())
      |> tag(:value),
      min: 1
    )
    |> tag(:cosem)
  end

  @manufacturer Enum.map(@separator ++ [?5], fn s -> {:not, s} end)
  def manufacturer do
    utf8_char(@manufacturer)
    |> times(min: 1)
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:manufacturer)
  end

  @model Enum.map(@separator, fn s -> {:not, s} end)
  def model do
    utf8_char(@model)
    |> times(min: 1)
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:model)
  end

  def header do
    ignore(utf8_char([?/]))
    |> concat(manufacturer())
    |> ignore(utf8_char([?5]))
    |> concat(model())
    |> tag(:header)
    |> label("header")
  end

  @footer Enum.map(@separator, fn s -> {:not, s} end)
  def footer do
    ignore(utf8_char([?!]))
    |> repeat(utf8_char(@footer))
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:footer)
    |> label("footer")
  end

  def lines do
    header()
    |> ignore(separator())
    |> ignore(separator())
    |> times(
      cosem()
      |> optional(separator() |> ignore()),
      min: 1
    )
    |> concat(footer())
    |> optional(separator() |> ignore())
    |> eos()
  end
end
