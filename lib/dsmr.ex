defmodule DSMR do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @type parse_opt() :: {:checksum, boolean()} | {:floats, :native | :decimals}

  defmodule ChecksumError do
    @moduledoc """
    Raised or returned when a telegram checksum does not match.

    Contains the checksum found in the telegram (`expected`) and the checksum
    computed from the telegram contents (`actual`).
    """

    @type t() :: %__MODULE__{expected: binary(), actual: binary()}

    defexception [:expected, :actual]

    @impl true
    def message(%__MODULE__{expected: expected, actual: actual}) do
      "checksum mismatch: telegram says #{inspect(expected)}, computed #{inspect(actual)}"
    end
  end

  defmodule ParseError do
    @moduledoc """
    Raised or returned when a telegram cannot be parsed.
    """

    @type t() :: %__MODULE__{message: binary()}

    defexception [:message]
  end

  alias DSMR.{Parser, Telegram}

  @doc """
  Parses a telegram and returns a `DSMR.Telegram` struct.

  This is the raising variant of `parse/2`.
  """
  @spec parse!(binary(), [parse_opt()]) :: Telegram.t() | no_return()
  def parse!(string, options \\ []) do
    case parse(string, options) do
      {:ok, telegram} -> telegram
      {:error, error} -> raise error
    end
  end

  @doc """
  Parses a telegram.

  Returns `{:ok, telegram}` on success. Invalid input returns
  `{:error, %DSMR.ParseError{}}`; checksum mismatches return
  `{:error, %DSMR.ChecksumError{}}`.

  ## Options

    * `:checksum` - validates the CRC16 checksum when `true`. Defaults to `true`.

    * `:floats` - controls how decimal numbers are parsed:

      * `:native` - returns native floats. This is the default.
      * `:decimals` - returns `%Decimal{}` structs for decimal values.
  """
  @spec parse(binary(), [parse_opt()]) ::
          {:ok, Telegram.t()} | {:error, ParseError.t() | ChecksumError.t()}
  def parse(string, options \\ []) when is_binary(string) and is_list(options) do
    validate_checksum = Keyword.get(options, :checksum, true)

    with {:ok, telegram} <- do_parse(string, options),
         :ok <- validate_checksum(string, telegram, validate_checksum) do
      {:ok, telegram}
    end
  end

  defp validate_checksum(_string, _telegram, false), do: :ok

  # Empty checksum is valid for DSMR 2.2
  defp validate_checksum(_string, %Telegram{checksum: ""}, true), do: :ok

  defp validate_checksum(string, %Telegram{checksum: expected}, true) do
    # A successfully parsed telegram always ends with "!" <> checksum <> "\r\n",
    # and the CRC16 covers everything up to and including the "!".
    crc_length = byte_size(string) - byte_size(expected) - 2
    actual = DSMR.CRC16.checksum(binary_part(string, 0, crc_length))

    if actual === String.upcase(expected) do
      :ok
    else
      {:error, %ChecksumError{expected: expected, actual: actual}}
    end
  end

  defp do_parse(string, options) do
    case Parser.parse(string, options) do
      {:ok, _telegram} = result ->
        result

      # errors already built by the parser pass through unchanged
      {:error, %ParseError{}} = error ->
        error

      # handle leex errors: {:error, {Line, Module, Reason}, Tokens}
      {:error, error, _} ->
        {:error, format_parse_error(error)}

      # handle yecc errors: {:error, {Line, Module, Message}}
      {:error, error} ->
        {:error, format_parse_error(error)}
    end
  end

  defp format_parse_error({line, :dsmr_lexer, reason}) do
    detail = :dsmr_lexer.format_error(reason)
    %DSMR.ParseError{message: "unexpected character while parsing (line #{line}: #{detail})"}
  end

  defp format_parse_error({line, :dsmr_parser, message}) do
    detail = if is_list(message), do: IO.iodata_to_binary(message), else: inspect(message)
    %DSMR.ParseError{message: "unexpected token while parsing (line #{line}: #{detail})"}
  end
end
