defmodule DSMR.TelegramTest do
  use ExUnit.Case, async: true

  alias DSMR.{Measurement, MBusDevice, Telegram, Timestamp}

  describe "to_string/1" do
    test "minimal telegram with header and checksum only" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "1234"
      }

      result = Telegram.to_string(telegram)

      assert result == "/TEST\r\n\r\n!1234\r\n"
    end

    test "telegram with version field" do
      telegram = %Telegram{
        header: "ISk5\\2MT382-1000",
        checksum: "5106",
        version: "50"
      }

      result = Telegram.to_string(telegram)

      assert result == "/ISk5\\2MT382-1000\r\n\r\n1-3:0.2.8(50)\r\n!5106\r\n"
    end

    test "telegram with measurements" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "ABCD",
        electricity_delivered_1: %Measurement{value: 1234.567, unit: "kWh"},
        electricity_currently_delivered: %Measurement{value: 1.5, unit: "kW"}
      }

      result = Telegram.to_string(telegram)

      assert result =~ "1-0:1.8.1(001234.567*kWh)"
      assert result =~ "1-0:1.7.0(000001.5*kW)"
    end

    test "telegram with zero values" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "0000",
        electricity_delivered_1: %Measurement{value: 0.0, unit: "kWh"},
        electricity_currently_delivered: %Measurement{value: 0, unit: "kW"}
      }

      result = Telegram.to_string(telegram)

      assert result =~ "1-0:1.8.1(000000*kWh)"
      assert result =~ "1-0:1.7.0(000000*kW)"
    end

    test "telegram with timestamp without DST" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "1111",
        measured_at: %Timestamp{
          value: ~N[2017-01-02 19:20:02],
          dst: nil
        }
      }

      result = Telegram.to_string(telegram)

      assert result =~ "0-0:1.0.0(170102192002)"
    end

    test "telegram with timestamp with DST" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "2222",
        measured_at: %Timestamp{
          value: ~N[2016-11-13 20:57:57],
          dst: "W"
        }
      }

      result = Telegram.to_string(telegram)

      assert result =~ "0-0:1.0.0(161113205757W)"
    end

    test "telegram with string fields" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "3333",
        equipment_id: "4B384547303034303436333935353037",
        electricity_tariff_indicator: "0002"
      }

      result = Telegram.to_string(telegram)

      assert result =~ "0-0:96.1.1(4B384547303034303436333935353037)"
      assert result =~ "0-0:96.14.0(0002)"
    end

    test "telegram with empty power failures log" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "4444",
        power_failures_log: []
      }

      result = Telegram.to_string(telegram)

      assert result =~ "1-0:99.97.0(0)(0-0:96.7.19)"
    end

    test "telegram with power failures log entries" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "5555",
        power_failures_log: [
          [
            %Timestamp{value: ~N[2000-01-04 18:03:20], dst: "W"},
            %Measurement{value: 237_126, unit: "s"}
          ],
          [
            %Timestamp{value: ~N[2000-01-01 00:00:01], dst: "W"},
            %Measurement{value: 2_147_583_646, unit: "s"}
          ]
        ]
      }

      result = Telegram.to_string(telegram)

      assert result =~
               "1-0:99.97.0(2)(0-0:96.7.19)(000104180320W)(237126*s)(000101000001W)(2147583646*s)"
    end

    test "telegram with single MBus device" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "6666",
        mbus_devices: [
          %MBusDevice{
            channel: 1,
            device_type: "003",
            equipment_id: "3232323241424344313233343536373839",
            last_reading_measured_at: %Timestamp{value: ~N[2017-01-02 16:10:05], dst: "W"},
            last_reading_value: %Measurement{value: 0.107, unit: "m3"}
          }
        ]
      }

      result = Telegram.to_string(telegram)

      assert result =~ "0-1:24.1.0(003)"
      assert result =~ "0-1:96.1.0(3232323241424344313233343536373839)"
      assert result =~ "0-1:24.2.1(170102161005W)(000000.107*m3)"
    end

    test "telegram with multiple MBus devices" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "7777",
        mbus_devices: [
          %MBusDevice{
            channel: 1,
            device_type: "003",
            equipment_id: "1111"
          },
          %MBusDevice{
            channel: 2,
            device_type: "003",
            equipment_id: "2222"
          }
        ]
      }

      result = Telegram.to_string(telegram)

      assert result =~ "0-1:24.1.0(003)"
      assert result =~ "0-1:96.1.0(1111)"
      assert result =~ "0-2:24.1.0(003)"
      assert result =~ "0-2:96.1.0(2222)"
    end

    test "telegram with MBus device with valve position" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "8888",
        mbus_devices: [
          %MBusDevice{
            channel: 1,
            device_type: "3",
            equipment_id: "000000000000",
            valve_position: "1"
          }
        ]
      }

      result = Telegram.to_string(telegram)

      assert result =~ "0-1:24.4.0(1)"
    end

    test "round-trip: parse v4.2 telegram, convert to string, parse again" do
      original_telegram_str =
        Enum.join([
          "/KFM5KAIFA-METER\r\n",
          "\r\n",
          "1-3:0.2.8(42)\r\n",
          "0-0:1.0.0(161113205757W)\r\n",
          "0-0:96.1.1(3960221976967177082151037881335713)\r\n",
          "1-0:1.8.1(001581.123*kWh)\r\n",
          "1-0:1.8.2(001435.706*kWh)\r\n",
          "1-0:2.8.1(000000.000*kWh)\r\n",
          "1-0:2.8.2(000000.000*kWh)\r\n",
          "0-0:96.14.0(0002)\r\n",
          "1-0:1.7.0(02.027*kW)\r\n",
          "1-0:2.7.0(00.000*kW)\r\n",
          "!6796\r\n"
        ])

      {:ok, parsed} = DSMR.parse(original_telegram_str, checksum: false)
      converted = Telegram.to_string(parsed)
      {:ok, reparsed} = DSMR.parse(converted, checksum: false)

      # Compare key fields
      assert reparsed.header == parsed.header
      assert reparsed.version == parsed.version
      assert reparsed.measured_at == parsed.measured_at
      assert reparsed.equipment_id == parsed.equipment_id
      assert reparsed.electricity_delivered_1.value == parsed.electricity_delivered_1.value
      assert reparsed.electricity_delivered_2.value == parsed.electricity_delivered_2.value
    end

    test "round-trip: parse v5.0 telegram, convert to string, parse again" do
      original_telegram_str =
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
          "1-0:32.7.0(0230.0*V)\r\n",
          "1-0:31.7.0(0.48*A)\r\n",
          "0-1:24.1.0(003)\r\n",
          "0-1:96.1.0(3232323241424344313233343536373839)\r\n",
          "0-1:24.2.1(170102161005W)(00000.107*m3)\r\n",
          "!6EEE\r\n"
        ])

      {:ok, parsed} = DSMR.parse(original_telegram_str, checksum: false)
      converted = Telegram.to_string(parsed)
      {:ok, reparsed} = DSMR.parse(converted, checksum: false)

      # Compare structs
      assert reparsed.header == parsed.header
      assert reparsed.version == parsed.version
      assert reparsed.measured_at == parsed.measured_at
      assert reparsed.voltage_l1.value == parsed.voltage_l1.value
      assert reparsed.phase_power_current_l1.value == parsed.phase_power_current_l1.value
      assert length(reparsed.mbus_devices) == length(parsed.mbus_devices)
    end

    test "fields appear in correct order" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "9999",
        version: "50",
        equipment_id: "ABCD",
        electricity_delivered_1: %Measurement{value: 1.0, unit: "kWh"},
        voltage_l1: %Measurement{value: 230.0, unit: "V"}
      }

      result = Telegram.to_string(telegram)
      lines = String.split(result, "\r\n", trim: true)

      # Version should come before equipment_id
      version_idx = Enum.find_index(lines, &String.starts_with?(&1, "1-3:0.2.8"))
      equipment_idx = Enum.find_index(lines, &String.starts_with?(&1, "0-0:96.1.1"))

      assert version_idx < equipment_idx

      # electricity_delivered_1 should come before voltage_l1
      electricity_idx = Enum.find_index(lines, &String.starts_with?(&1, "1-0:1.8.1"))
      voltage_idx = Enum.find_index(lines, &String.starts_with?(&1, "1-0:32.7.0"))

      assert electricity_idx < voltage_idx
    end

    test "omits nil fields" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "AAAA",
        version: "50",
        equipment_id: nil,
        electricity_delivered_1: nil
      }

      result = Telegram.to_string(telegram)

      assert result =~ "1-3:0.2.8(50)"
      refute result =~ "0-0:96.1.1"
      refute result =~ "1-0:1.8.1"
    end

    test "omits empty string fields" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "BBBB",
        version: "50",
        equipment_id: ""
      }

      result = Telegram.to_string(telegram)

      assert result =~ "1-3:0.2.8(50)"
      refute result =~ "0-0:96.1.1"
    end

    test "formats float precision correctly" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "CCCC",
        electricity_delivered_1: %Measurement{value: 0.001, unit: "kWh"},
        electricity_delivered_2: %Measurement{value: 123.456, unit: "kWh"}
      }

      result = Telegram.to_string(telegram)

      assert result =~ "1-0:1.8.1(000000.001*kWh)"
      assert result =~ "1-0:1.8.2(000123.456*kWh)"
    end

    test "handles Decimal values when present" do
      telegram = %Telegram{
        header: "TEST",
        checksum: "DDDD",
        electricity_delivered_1: %Measurement{value: Decimal.new("1581.123"), unit: "kWh"}
      }

      result = Telegram.to_string(telegram)

      assert result =~ "1-0:1.8.1(001581.123*kWh)"
    end
  end
end
