defmodule DSMR.TimestampTest do
  use ExUnit.Case, async: true

  alias DSMR.Timestamp

  describe "to_datetime/1" do
    test "winter time (W) is UTC+1" do
      timestamp = %Timestamp{value: ~N[2017-01-02 19:20:02], dst: "W"}

      assert Timestamp.to_datetime(timestamp) == {:ok, ~U[2017-01-02 18:20:02Z]}
    end

    test "summer time (S) is UTC+2" do
      timestamp = %Timestamp{value: ~N[2017-07-02 19:20:02], dst: "S"}

      assert Timestamp.to_datetime(timestamp) == {:ok, ~U[2017-07-02 17:20:02Z]}
    end

    test "missing DST marker returns an error" do
      timestamp = %Timestamp{value: ~N[2017-01-02 19:20:02], dst: nil}

      assert Timestamp.to_datetime(timestamp) == {:error, :missing_dst}
    end

    test "works on a timestamp from a parsed telegram" do
      telegram =
        Enum.join([
          "/TEST\r\n",
          "\r\n",
          "0-0:1.0.0(170102192002W)\r\n",
          "!XXXX\r\n"
        ])

      {:ok, parsed} = DSMR.parse(telegram, checksum: false)

      assert Timestamp.to_datetime(parsed.measured_at) == {:ok, ~U[2017-01-02 18:20:02Z]}
    end
  end
end
