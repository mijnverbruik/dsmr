defmodule DSMR.Parser do
  @moduledoc false

  alias DSMR.{Measurement, Telegram, Timestamp}

  # @spec parse(binary(), keyword()) ::
  #         {:ok, Telegram.t()} | {:error, binary(), binary()}
  # def parse(input, options) do
  #   tokenize_opts = [context: %{floats: Keyword.get(options, :floats, :native)}]

  #   case do_parse(input, tokenize_opts) do
  #     {:ok, tokens, "", _, _, _} ->
  #       [{:header, header}, {:data, data}, {:footer, checksum}] = tokens
  #       {:ok, %Telegram{header: header, data: data, checksum: checksum}}

  #     {:error, reason, rest, _, _, _} ->
  #       {:error, reason, rest}
  #   end
  # end

  # @spec do_parse(binary()) ::
  #         {:ok, [any()], binary(), map(), {pos_integer(), pos_integer()}, pos_integer()}
  #         | {:error, String.t(), String.t(), map(), {non_neg_integer(), non_neg_integer()},
  #            non_neg_integer()}

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
      telegram =
        Enum.reduce(parsed, %Telegram{}, fn item, acc ->
          reduce_to_value(item, acc, opts)
        end)

      {:ok, telegram}
    end
  end

  defp reduce_to_value({:header, header}, telegram, _opts) do
    %{telegram | header: header}
  end

  defp reduce_to_value({:checksum, checksum}, telegram, _opts) do
    %{telegram | checksum: checksum}
  end

  defp reduce_to_value({:object, object}, telegram, opts) do
    data =
      object
      |> Enum.reduce([], fn item, acc ->
        reduce_to_value(item, acc, opts)
      end)
      |> List.to_tuple()

    %{telegram | data: telegram.data ++ [data]}
  end

  defp reduce_to_value({:measurement, value, unit}, object, opts) do
    [processed_value] = reduce_to_value(value, [], opts)
    object ++ [%Measurement{unit: unit, value: processed_value}]
  end

  defp reduce_to_value(
         {:timestamp, {[year, month, day, hour, minute, second], dst}},
         object,
         _opts
       ) do
    timestamp = NaiveDateTime.new!(2000 + year, month, day, hour, minute, second)
    object ++ [%Timestamp{value: timestamp, dst: dst}]
  end

  defp reduce_to_value({:float, value}, object, %{floats: :native} = _opts) do
    object ++ [:erlang.binary_to_float(value)]
  end

  defp reduce_to_value({:float, value}, object, %{floats: :decimals} = _opts) do
    # silence xref warning
    decimal = Decimal
    object ++ [decimal.new(value)]
  end

  defp reduce_to_value({:int, value}, object, _opts) do
    object ++ [:erlang.binary_to_integer(value)]
  end

  defp reduce_to_value({_token, value}, object, _opts) do
    object ++ [value]
  end

  defp reduce_to_value(value, object, _opts) do
    object ++ [value]
  end
end
