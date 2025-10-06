defmodule DSMR.TelegramFixtures do
  @moduledoc """
  Telegram fixtures for testing both happy paths and error cases.
  """

  @doc """
  Returns a basic telegram with valid structure.
  """
  def basic_telegram(checksum \\ "2A99") do
    Enum.join([
      "/TEST\r\n",
      "\r\n",
      "1-3:0.2.8(50)\r\n",
      "!#{checksum}\r\n"
    ])
  end

  @doc """
  Returns a telegram with maximum M-Bus devices (4 channels).
  """
  def max_mbus_telegram do
    Enum.join([
      "/TEST\r\n",
      "\r\n",
      "0-1:24.1.0(003)\r\n",
      "0-1:96.1.0(1111111111111111)\r\n",
      "0-1:24.2.1(230101120000W)(00111.111*m3)\r\n",
      "0-2:24.1.0(003)\r\n",
      "0-2:96.1.0(2222222222222222)\r\n",
      "0-2:24.2.1(230101120000W)(00222.222*m3)\r\n",
      "0-3:24.1.0(007)\r\n",
      "0-3:96.1.0(3333333333333333)\r\n",
      "0-3:24.2.1(230101120000W)(00333.333*m3)\r\n",
      "0-4:24.1.0(003)\r\n",
      "0-4:96.1.0(4444444444444444)\r\n",
      "0-4:24.2.1(230101120000W)(00444.444*m3)\r\n",
      "!366F\r\n"
    ])
  end

  @doc """
  Returns a three-phase power telegram with voltage, current, and power measurements.
  """
  def three_phase_telegram(opts \\ []) do
    checksum = Keyword.get(opts, :checksum, "AA23")

    Enum.join([
      "/TEST\r\n",
      "\r\n",
      "1-3:0.2.8(50)\r\n",
      "1-0:32.7.0(0230.0*V)\r\n",
      "1-0:52.7.0(0230.0*V)\r\n",
      "1-0:72.7.0(0229.0*V)\r\n",
      "1-0:31.7.0(0.48*A)\r\n",
      "1-0:51.7.0(0.44*A)\r\n",
      "1-0:71.7.0(0.86*A)\r\n",
      "1-0:21.7.0(00.070*kW)\r\n",
      "1-0:41.7.0(00.032*kW)\r\n",
      "1-0:61.7.0(00.142*kW)\r\n",
      "!#{checksum}\r\n"
    ])
  end

  @doc """
  Returns a telegram with power failures log.
  """
  def power_failures_telegram(event_count \\ 1) do
    events =
      for i <- 1..event_count do
        # Format: YYMMDDhhmmssX timestamp and duration
        day = String.pad_leading(to_string(rem(i - 1, 28) + 1), 2, "0")
        "(0001#{day}180320W)(00002371#{String.pad_leading(to_string(i), 2, "0")}*s)"
      end
      |> Enum.join()

    Enum.join([
      "/TEST\r\n",
      "\r\n",
      "1-0:99.97.0(#{event_count})(0-0:96.7.19)#{events}\r\n",
      "!AA23\r\n"
    ])
  end

  @doc """
  Returns a telegram with text messages.
  """
  def text_message_telegram(opts \\ []) do
    code = Keyword.get(opts, :code, "303132")
    message = Keyword.get(opts, :message, "303132333435363738")
    checksum = Keyword.get(opts, :checksum, "AA23")

    code_line = if code, do: "0-0:96.13.1(#{code})\r\n", else: ""
    message_line = if message, do: "0-0:96.13.0(#{message})\r\n", else: ""

    Enum.join([
      "/TEST\r\n",
      "\r\n",
      code_line,
      message_line,
      "!#{checksum}\r\n"
    ])
  end

  @doc """
  Returns a telegram with unknown OBIS codes.
  """
  def unknown_obis_telegram(count \\ 2) do
    unknown_codes =
      for i <- 1..count do
        "9-#{i}:99.99.99(#{i * 100})\r\n"
      end
      |> Enum.join()

    Enum.join([
      "/TEST\r\n",
      "\r\n",
      unknown_codes,
      "!AA23\r\n"
    ])
  end

  # Error case fixtures

  @doc """
  Returns a telegram with an invalid checksum.
  """
  def invalid_checksum_telegram do
    Enum.join([
      "/TEST\r\n",
      "\r\n",
      "1-3:0.2.8(50)\r\n",
      "!WRONG\r\n"
    ])
  end

  @doc """
  Returns a telegram with invalid timestamp (month 13).
  """
  def invalid_timestamp_telegram(type \\ :invalid_month) do
    timestamp =
      case type do
        :invalid_month -> "991399235959W"
        :invalid_day -> "991132235959W"
        :invalid_hour -> "991130245959W"
        :invalid_minute -> "991130236059W"
        :invalid_second -> "991130235960W"
        :feb_30 -> "990230120000W"
        :too_short -> "99113023W"
        :too_long -> "99113023595999W"
      end

    Enum.join([
      "/TEST\r\n",
      "\r\n",
      "0-0:1.0.0(#{timestamp})\r\n",
      "!XXXX\r\n"
    ])
  end

  @doc """
  Returns a telegram with invalid measurement value.
  """
  def invalid_measurement_telegram(type \\ :multiple_decimals) do
    value =
      case type do
        :multiple_decimals -> "123.45.67*kWh"
        :no_asterisk -> "123.45kWh"
        :empty_value -> "*kWh"
      end

    Enum.join([
      "/TEST\r\n",
      "\r\n",
      "1-0:1.8.1(#{value})\r\n",
      "!AA23\r\n"
    ])
  end

  @doc """
  Returns a truncated telegram.
  """
  def truncated_telegram(type \\ :mid_line) do
    case type do
      :mid_line -> "/TEST\r\n\r\n1-3:0.2.8(5"
      :mid_obis -> "/TEST\r\n\r\n1-3:0"
      :mid_measurement -> "/TEST\r\n\r\n1-0:1.8.1(001581.12"
      :no_delimiter -> "/TEST\r\n\r\n1-3:0.2.8(50)\r\n"
      :no_final_crlf -> "/TEST\r\n\r\n1-3:0.2.8(50)\r\n!5106"
    end
  end

  @doc """
  Returns a telegram with malformed structure.
  """
  def malformed_structure_telegram(type \\ :no_opening_paren) do
    case type do
      :no_opening_paren -> "/TEST\r\n\r\n1-0:1.8.1123.45*kWh)\r\n!AA23\r\n"
      :no_closing_paren -> "/TEST\r\n\r\n1-0:1.8.1(123.45*kWh\r\n!AA23\r\n"
      :empty_attrs -> "/TEST\r\n\r\n1-0:1.8.1()\r\n!AA23\r\n"
    end
  end

  @doc """
  Returns a telegram with checksum format variations.
  """
  def checksum_format_telegram(type \\ :lowercase) do
    checksum =
      case type do
        :lowercase -> "5106"
        :mixed_case -> "aA12"
        :three_digits -> "ABC"
        :five_digits -> "ABCDE"
        :non_hex -> "GHIJ"
        :empty -> ""
      end

    Enum.join([
      "/TEST\r\n",
      "\r\n",
      "1-3:0.2.8(50)\r\n",
      "!#{checksum}\r\n"
    ])
  end

  @doc """
  Returns a telegram with line ending variations.
  """
  def line_ending_telegram(type \\ :lf_only) do
    case type do
      :lf_only -> "/TEST\n\n1-3:0.2.8(50)\n!2A99\n"
      :mixed -> "/TEST\r\n\n1-3:0.2.8(50)\n!2A99\r\n"
      :extra_blanks -> "/TEST\r\n\r\n\r\n1-3:0.2.8(50)\r\n\r\n!2A99\r\n"
    end
  end

  @doc """
  Returns a telegram with header variations.
  """
  def header_variation_telegram(header) do
    Enum.join([
      "/#{header}\r\n",
      "\r\n",
      "1-3:0.2.8(50)\r\n",
      "!AA23\r\n"
    ])
  end

  # Version-specific telegram fixtures

  @doc """
  Returns a DSMR v2.2 telegram.
  """
  def dsmr_v22_telegram do
    Enum.join([
      "/ISk5\\2MT382-1004\r\n",
      "\r\n",
      "0-0:96.1.1(00000000000000)\r\n",
      "1-0:1.8.1(00001.001*kWh)\r\n",
      "1-0:2.8.1(00001.001*kWh)\r\n",
      "0-0:96.14.0(0001)\r\n",
      "1-0:1.7.0(0001.01*kW)\r\n",
      "0-0:96.13.1()\r\n",
      "0-1:24.1.0(3)\r\n",
      "0-1:96.1.0(000000000000)\r\n",
      "0-1:24.3.0(161107190000)(00)(60)(1)(0-1:24.2.1)(m3)\r\n",
      "(00001.001)\r\n",
      "!\r\n"
    ])
  end

  @doc """
  Returns a DSMR v3.0 telegram.
  """
  def dsmr_v30_telegram do
    Enum.join([
      "/ISk5\\2MT382-1000\r\n",
      "\r\n",
      "0-0:96.1.1(4B384547303034303436333935353037)\r\n",
      "1-0:1.8.1(12345.678*kWh)\r\n",
      "1-0:2.8.2(12345.678*kWh)\r\n",
      "0-0:96.14.0(0002)\r\n",
      "1-0:1.7.0(001.19*kW)\r\n",
      "0-0:96.13.1(303132333435363738)\r\n",
      "0-1:24.1.0(03)\r\n",
      "0-1:96.1.0(3232323241424344313233343536373839)\r\n",
      "0-1:24.3.0(090212160000)(00)(60)(1)(0-1:24.2.1)(m3)\r\n",
      "(00001.001)\r\n",
      "!\r\n"
    ])
  end

  @doc """
  Returns a DSMR v4.0 telegram with power failures.
  """
  def dsmr_v40_telegram do
    Enum.join([
      "/KFM5KAIFA-METER\r\n",
      "\r\n",
      "1-3:0.2.8(40)\r\n",
      "0-0:1.0.0(161113205757W)\r\n",
      "0-0:96.1.1(3960221976967177082151037881335713)\r\n",
      "1-0:1.8.1(001581.123*kWh)\r\n",
      "1-0:2.8.2(000000.000*kWh)\r\n",
      "0-0:96.7.21(00015)\r\n",
      "1-0:99.97.0(2)(0-0:96.7.19)(000104180320W)(0000237126*s)(000101000001W)(2147583646*s)\r\n",
      "0-0:96.13.0()\r\n",
      "!AA23\r\n"
    ])
  end

  @doc """
  Returns a full-featured telegram with all major fields populated.
  """
  def full_featured_telegram do
    Enum.join([
      "/ISk5\\2MT382-1000\r\n",
      "\r\n",
      "1-3:0.2.8(50)\r\n",
      "0-0:1.0.0(170102192002W)\r\n",
      "0-0:96.1.1(4B384547303034303436333935353037)\r\n",
      "1-0:1.8.1(000004.426*kWh)\r\n",
      "1-0:1.8.2(000002.399*kWh)\r\n",
      "1-0:2.8.1(000002.444*kWh)\r\n",
      "1-0:2.8.2(000000.000*kWh)\r\n",
      "0-0:96.14.0(0002)\r\n",
      "1-0:1.7.0(00.244*kW)\r\n",
      "1-0:2.7.0(00.000*kW)\r\n",
      "0-0:96.7.21(00013)\r\n",
      "0-0:96.7.9(00000)\r\n",
      "1-0:99.97.0(0)(0-0:96.7.19)\r\n",
      "1-0:32.7.0(0230.0*V)\r\n",
      "1-0:52.7.0(0230.0*V)\r\n",
      "1-0:72.7.0(0229.0*V)\r\n",
      "1-0:31.7.0(0.48*A)\r\n",
      "1-0:51.7.0(0.44*A)\r\n",
      "1-0:71.7.0(0.86*A)\r\n",
      "1-0:21.7.0(00.070*kW)\r\n",
      "1-0:41.7.0(00.032*kW)\r\n",
      "1-0:61.7.0(00.142*kW)\r\n",
      "0-1:24.1.0(003)\r\n",
      "0-1:96.1.0(3232323241424344313233343536373839)\r\n",
      "0-1:24.2.1(170102161005W)(00000.107*m3)\r\n",
      "!AA23\r\n"
    ])
  end

  @doc """
  Returns a valid M-Bus device telegram for a specific channel.
  """
  def mbus_device_telegram(channel, opts \\ []) do
    device_type = Keyword.get(opts, :device_type, "003")

    equipment_id =
      Keyword.get(
        opts,
        :equipment_id,
        "#{channel}#{channel}#{channel}#{channel}#{channel}#{channel}#{channel}#{channel}"
      )

    reading = Keyword.get(opts, :reading, true)
    valve = Keyword.get(opts, :valve_position)
    checksum = Keyword.get(opts, :checksum, "AA23")

    reading_lines =
      if reading do
        "0-#{channel}:24.2.1(230101120000W)(00#{channel * 111}.#{channel * 111}*m3)\r\n"
      else
        ""
      end

    valve_line = if valve, do: "0-#{channel}:24.4.0(#{valve})\r\n", else: ""

    Enum.join([
      "/TEST\r\n",
      "\r\n",
      "0-#{channel}:24.1.0(#{device_type})\r\n",
      "0-#{channel}:96.1.0(#{equipment_id})\r\n",
      reading_lines,
      valve_line,
      "!#{checksum}\r\n"
    ])
  end
end
