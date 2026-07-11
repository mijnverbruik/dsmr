defmodule DSMR.Timestamp do
  @moduledoc """
  A DSMR timestamp.

  DSMR timestamps contain a naive date and time. Some telegrams also include a
  daylight saving time marker: `"W"` for winter time or `"S"` for summer time.
  """

  @enforce_keys [:value]
  defstruct [:value, dst: nil]

  @type t() :: %__MODULE__{
          value: NaiveDateTime.t(),
          dst: binary() | nil
        }

  # Dutch local time: UTC+1 in winter ("W"), UTC+2 in summer ("S").
  @dst_offsets %{"W" => 3600, "S" => 7200}

  @doc """
  Converts a timestamp to a UTC `DateTime`.

  DSMR timestamps are Dutch local time; the DST marker disambiguates the UTC
  offset (`"W"` means UTC+1, `"S"` means UTC+2). The fixed offsets make this
  conversion work without a timezone database dependency.

  Returns `{:error, :missing_dst}` for timestamps without a DST marker
  (found in DSMR 2.2/3.0 telegrams), as their UTC offset is ambiguous around
  the DST transitions.

  ## Examples

      iex> DSMR.Timestamp.to_datetime(%DSMR.Timestamp{value: ~N[2017-01-02 19:20:02], dst: "W"})
      {:ok, ~U[2017-01-02 18:20:02Z]}

      iex> DSMR.Timestamp.to_datetime(%DSMR.Timestamp{value: ~N[2017-07-02 19:20:02], dst: "S"})
      {:ok, ~U[2017-07-02 17:20:02Z]}

      iex> DSMR.Timestamp.to_datetime(%DSMR.Timestamp{value: ~N[2017-01-02 19:20:02]})
      {:error, :missing_dst}

  """
  @spec to_datetime(t()) :: {:ok, DateTime.t()} | {:error, :missing_dst}
  def to_datetime(%__MODULE__{value: value, dst: dst}) do
    case @dst_offsets do
      %{^dst => offset} ->
        datetime =
          value
          |> NaiveDateTime.add(-offset)
          |> DateTime.from_naive!("Etc/UTC")

        {:ok, datetime}

      _ ->
        {:error, :missing_dst}
    end
  end
end
