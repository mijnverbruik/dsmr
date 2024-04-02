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

    with {:ok, telegram} <- do_parse(string, options),
         :ok <- valid_checksum?(telegram, string, validate_checksum) do
      {:ok, telegram}
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

  defp format_parse_error({_, :dsmr_lexer, _}) do
    %DSMR.ParseError{message: "unexpected character while parsing"}
  end

  defp format_parse_error({_, :dsmr_parser, _}) do
    %DSMR.ParseError{message: "unexpected token while parsing"}
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

  defp valid_checksum?(_telegram, _string, false), do: :ok
  defp valid_checksum?(%DSMR.Telegram{checksum: ""}, _string, _), do: :ok

  defp valid_checksum?(%DSMR.Telegram{} = telegram, string, _) do
    [raw, _rest] = String.split(string, "!")
    checksum = DSMR.CRC16.checksum(raw <> "!")

    if checksum === telegram.checksum do
      :ok
    else
      {:error, %ChecksumError{checksum: checksum}}
    end
  end
end
