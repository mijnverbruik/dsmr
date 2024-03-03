defmodule DSMR do
  @moduledoc """
  A library for parsing Dutch Smart Meter Requirements (DSMR) telegram data.
  """

  defmodule ChecksumError do
    defexception [:checksum]

    @impl true
    def message(_exception), do: "checksum mismatch"
  end

  @doc """
  Parses telegram data from a string and returns a struct.
  """
  @spec parse(binary(), keyword()) :: {:ok, DSMR.Telegram.t()} | {:error, any()}
  def parse(string, options \\ []) when is_binary(string) and is_list(options) do
    validate_checksum = Keyword.get(options, :checksum, true)

    with {:ok, tokens} <- DSMR.Lexer.tokenize(string, options),
         {:ok, telegram} <- :dsmr_parser.parse(tokens),
         :ok <- valid_checksum?(telegram, string, validate_checksum) do
      {:ok, telegram}
    end
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
