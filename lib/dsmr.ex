defmodule DSMR do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @type parse_opt :: {:checksum, boolean} | {:floats, :native | :decimals}

  defmodule ChecksumError do
    @type t :: %__MODULE__{checksum: binary()}

    defexception [:checksum]

    @impl true
    def message(_exception), do: "checksum mismatch"
  end

  defmodule ParseError do
    @type t :: %__MODULE__{message: binary()}

    defexception [:message]
  end

  alias DSMR.{Parser, Telegram}

  @doc """
  Parses telegram data from a string and returns a `DSMR.Telegram` struct.

  Similar to `parse/2` except it will unwrap the error tuple and raise
  in case of errors.
  """
  @spec parse!(binary, [parse_opt]) :: Telegram.t() | no_return
  def parse!(string, options \\ []) do
    case parse(string, options) do
      {:ok, telegram} -> telegram
      {:error, error} -> raise error
    end
  end

  @doc """
  Parses telegram data from a string and returns a `DSMR.Telegram` struct.

  ## Options

    * `:checksum` - when true, the checksum will be validated, defaults to `true`.

    * `:floats` - controls how floats are parsed. Possible values are:

      * `:native` (default) - Native conversion from binary to float using `:erlang.binary_to_float/1`,
      * `:decimals` - uses `Decimal.new/1` to parse the binary into a Decimal struct with arbitrary precision.
  """
  @spec parse(binary, [parse_opt]) ::
          {:ok, Telegram.t()} | {:error, ParseError.t() | ChecksumError.t()}
  def parse(string, options \\ []) when is_binary(string) and is_list(options) do
    validate_checksum = Keyword.get(options, :checksum, true)

    with :ok <- early_checksum_validation(string, validate_checksum),
         {:ok, telegram} <- do_parse(string, options) do
      {:ok, telegram}
    end
  end

  defp early_checksum_validation(_string, false), do: :ok

  defp early_checksum_validation(string, true) do
    case String.split(string, "!", parts: 2) do
      [raw, rest] ->
        # Extract expected checksum from rest (the checksum is after the last "!" in the string)
        expected_checksum = rest |> String.trim() |> String.split("!") |> List.last() |> String.trim()

        # Empty checksum is valid for DSMR 2.2
        if expected_checksum === "" do
          :ok
        else
          # Calculate CRC16 on content before first "!"
          actual_checksum = DSMR.CRC16.checksum(raw <> "!")

          if actual_checksum === expected_checksum do
            :ok
          else
            {:error, %ChecksumError{checksum: actual_checksum}}
          end
        end

      [_] ->
        {:error, %ParseError{message: "checksum delimiter '!' not found"}}
    end
  end

  defp do_parse(string, options) do
    case Parser.parse(string, options) do
      {:ok, _telegram} = result ->
        result

      # handle leex errors: {:error, {Line, Module, Reason}, Tokens}
      {:error, error, _} ->
        {:error, format_parse_error(error)}

      # handle yecc errors: {:error, {Line, Module, Message}}
      {:error, error} ->
        {:error, format_parse_error(error)}
    end
  rescue
    # Catch any unexpected exceptions during parsing
    error ->
      {:error, format_parse_error(error)}
  end

  defp format_parse_error({line, :dsmr_lexer, reason}) do
    detail = :dsmr_lexer.format_error(reason)
    %DSMR.ParseError{message: "unexpected character while parsing (line #{line}: #{detail})"}
  end

  defp format_parse_error({line, :dsmr_parser, message}) do
    detail = if is_list(message), do: IO.iodata_to_binary(message), else: inspect(message)
    %DSMR.ParseError{message: "unexpected token while parsing (line #{line}: #{detail})"}
  end

  defp format_parse_error(%{} = error) do
    detail =
      if is_exception(error) do
        ": " <> Exception.message(error)
      else
        ""
      end

    message = "An unexpected error occurred while parsing" <> detail
    %ParseError{message: message}
  end
end
