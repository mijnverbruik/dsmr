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

  alias DSMR.Telegram

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
    try do
      case DSMR.Lexer.tokenize(string, options) do
        {:ok, tokens} ->
          case :dsmr_parser.parse(tokens) do
            {:ok, telegram} ->
              {:ok, telegram}

            {:error, raw_error} ->
              {:error, format_parse_error(raw_error)}
          end

        {:error, reason, rest} ->
          {:error, format_parse_error({:lexer, reason, rest})}
      end
    rescue
      error ->
        {:error, format_parse_error(error)}
    end
  end

  defp format_parse_error({_token, :dsmr_parser, msgs}) do
    message = msgs |> Enum.map(&to_string/1) |> Enum.join("")
    %ParseError{message: message}
  end

  defp format_parse_error({:lexer, _reason, rest}) do
    sample_slice = String.slice(rest, 0, 10)
    sample = if String.valid?(sample_slice), do: sample_slice, else: inspect(sample_slice)

    message = "Parsing failed at `#{sample}`"
    %ParseError{message: message}
  end

  defp format_parse_error(%{} = error) do
    detail =
      if is_exception(error) do
        ": " <> Exception.message(error)
      else
        ""
      end

    message = "An unknown error occurred while parsing" <> detail
    %ParseError{message: message}
  end

  defp valid_checksum?(_telegram, _string, false), do: :ok
  # @TODO Only skip empty checksums when telegram version does not require it.
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
