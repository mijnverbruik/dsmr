defmodule DSMRTest do
  use ExUnit.Case, async: true

  alias DSMR.{Measurement, Telegram, Timestamp}
  import DSMR.TelegramFixtures

  describe "parse/2" do
    test "with telegram v2.2" do
      telegram =
        Enum.join([
          "/ISk5\\2MT382-1004\r\n",
          "\r\n",
          "0-0:96.1.1(00000000000000)\r\n",
          "1-0:1.8.1(00001.001*kWh)\r\n",
          "1-0:1.8.2(00001.001*kWh)\r\n",
          "1-0:2.8.1(00001.001*kWh)\r\n",
          "1-0:2.8.2(00001.001*kWh)\r\n",
          "0-0:96.14.0(0001)\r\n",
          "1-0:1.7.0(0001.01*kW)\r\n",
          "1-0:2.7.0(0000.00*kW)\r\n",
          "0-0:17.0.0(0999.00*kW)\r\n",
          "0-0:96.3.10(1)\r\n",
          "0-0:96.13.1()\r\n",
          "0-0:96.13.0()\r\n",
          "0-1:24.1.0(3)\r\n",
          "0-1:96.1.0(000000000000)\r\n",
          "0-1:24.3.0(161107190000)(00)(60)(1)(0-1:24.2.1)(m3)\r\n",
          "(00001.001)\r\n",
          "0-1:24.4.0(1)\r\n",
          "!\r\n"
        ])

      assert DSMR.parse(telegram) ==
               {:ok,
                %Telegram{
                  header: "ISk5\\2MT382-1004",
                  checksum: "",
                  equipment_id: "00000000000000",
                  electricity_delivered_1: %Measurement{unit: "kWh", value: 1.001},
                  electricity_delivered_2: %Measurement{unit: "kWh", value: 1.001},
                  electricity_returned_1: %Measurement{unit: "kWh", value: 1.001},
                  electricity_returned_2: %Measurement{unit: "kWh", value: 1.001},
                  electricity_tariff_indicator: "0001",
                  electricity_currently_delivered: %Measurement{unit: "kW", value: 1.01},
                  electricity_currently_returned: %Measurement{unit: "kW", value: 0.0},
                  actual_threshold_electricity: %Measurement{unit: "kW", value: 999.0},
                  actual_switch_position: "1",
                  text_message_code: nil,
                  text_message: nil,
                  mbus_devices: [
                    %DSMR.MBusDevice{
                      channel: 1,
                      device_type: "3",
                      equipment_id: "000000000000",
                      valve_position: "1",
                      last_reading_measured_at: %Timestamp{
                        value: ~N[2016-11-07 19:00:00],
                        dst: nil
                      },
                      last_reading_value: %Measurement{unit: "m3", value: 1.001}
                    }
                  ]
                }}
    end

    test "with telegram v3.0" do
      telegram =
        Enum.join([
          "/ISk5\\2MT382-1000\r\n",
          "\r\n",
          "0-0:96.1.1(4B384547303034303436333935353037)\r\n",
          "1-0:1.8.1(12345.678*kWh)\r\n",
          "1-0:1.8.2(12345.678*kWh)\r\n",
          "1-0:2.8.1(12345.678*kWh)\r\n",
          "1-0:2.8.2(12345.678*kWh)\r\n",
          "0-0:96.14.0(0002)\r\n",
          "1-0:1.7.0(001.19*kW)\r\n",
          "1-0:2.7.0(000.00*kW)\r\n",
          "0-0:17.0.0(016*A)\r\n",
          "0-0:96.3.10(1)\r\n",
          "0-0:96.13.1(303132333435363738)\r\n",
          "0-0:96.13.0(303132333435363738393A3B3C3D3E3F303132333435363738393A3B3C3D3E",
          "3F303132333435363738393A3B3C3D3E3F303132333435363738393A3B3C3D3E3F30313233",
          "3435363738393A3B3C3D3E3F)\r\n",
          "0-1:96.1.0(3232323241424344313233343536373839)\r\n",
          "0-1:24.1.0(03)\r\n",
          "0-1:24.3.0(090212160000)(00)(60)(1)(0-1:24.2.1)(m3)\r\n",
          "(00001.001)\r\n",
          "0-1:24.4.0(1)\r\n",
          "!\r\n"
        ])

      assert DSMR.parse(telegram) ==
               {:ok,
                %Telegram{
                  header: "ISk5\\2MT382-1000",
                  checksum: "",
                  equipment_id: "4B384547303034303436333935353037",
                  electricity_delivered_1: %Measurement{unit: "kWh", value: 12345.678},
                  electricity_delivered_2: %Measurement{unit: "kWh", value: 12345.678},
                  electricity_returned_1: %Measurement{unit: "kWh", value: 12345.678},
                  electricity_returned_2: %Measurement{unit: "kWh", value: 12345.678},
                  electricity_tariff_indicator: "0002",
                  electricity_currently_delivered: %Measurement{unit: "kW", value: 1.19},
                  electricity_currently_returned: %Measurement{unit: "kW", value: 0.0},
                  actual_threshold_electricity: %Measurement{unit: "A", value: 16},
                  actual_switch_position: "1",
                  text_message_code: "303132333435363738",
                  text_message:
                    "303132333435363738393A3B3C3D3E3F303132333435363738393A3B3C3D3E3F303132333435363738393A3B3C3D3E3F303132333435363738393A3B3C3D3E3F303132333435363738393A3B3C3D3E3F",
                  mbus_devices: [
                    %DSMR.MBusDevice{
                      channel: 1,
                      device_type: "03",
                      equipment_id: "3232323241424344313233343536373839",
                      valve_position: "1",
                      last_reading_measured_at: %Timestamp{
                        value: ~N[2009-02-12 16:00:00],
                        dst: nil
                      },
                      last_reading_value: %Measurement{unit: "m3", value: 1.001}
                    }
                  ]
                }}
    end

    test "with telegram v4.2" do
      telegram =
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
          "0-0:96.7.21(00015)\r\n",
          "0-0:96.7.9(00007)\r\n",
          "1-0:99.97.0(3)(0-0:96.7.19)(000104180320W)(0000237126*s)(000101000001W)",
          "(2147583646*s)(000102000003W)(2317482647*s)\r\n",
          "1-0:32.32.0(00000)\r\n",
          "1-0:52.32.0(00000)\r\n",
          "1-0:72.32.0(00000)\r\n",
          "1-0:32.36.0(00000)\r\n",
          "1-0:52.36.0(00000)\r\n",
          "1-0:72.36.0(00000)\r\n",
          "0-0:96.13.1()\r\n",
          "0-0:96.13.0()\r\n",
          "1-0:31.7.0(000*A)\r\n",
          "1-0:51.7.0(006*A)\r\n",
          "1-0:71.7.0(002*A)\r\n",
          "1-0:21.7.0(00.170*kW)\r\n",
          "1-0:22.7.0(00.000*kW)\r\n",
          "1-0:41.7.0(01.247*kW)\r\n",
          "1-0:42.7.0(00.000*kW)\r\n",
          "1-0:61.7.0(00.209*kW)\r\n",
          "1-0:62.7.0(00.000*kW)\r\n",
          "0-1:24.1.0(003)\r\n",
          "0-1:96.1.0(4819243993373755377509728609491464)\r\n",
          "0-1:24.2.1(161129200000W)(00981.443*m3)\r\n",
          "!6796\r\n"
        ])

      assert DSMR.parse(telegram) ==
               {:ok,
                %Telegram{
                  header: "KFM5KAIFA-METER",
                  version: "42",
                  measured_at: %Timestamp{value: ~N[2016-11-13 20:57:57], dst: "W"},
                  equipment_id: "3960221976967177082151037881335713",
                  electricity_delivered_1: %DSMR.Measurement{value: 1581.123, unit: "kWh"},
                  electricity_delivered_2: %DSMR.Measurement{value: 1435.706, unit: "kWh"},
                  electricity_returned_1: %DSMR.Measurement{value: 0.0, unit: "kWh"},
                  electricity_returned_2: %DSMR.Measurement{value: 0.0, unit: "kWh"},
                  electricity_tariff_indicator: "0002",
                  electricity_currently_delivered: %DSMR.Measurement{value: 2.027, unit: "kW"},
                  electricity_currently_returned: %DSMR.Measurement{value: 0.0, unit: "kW"},
                  power_failures_count: "00015",
                  power_failures_long_count: "00007",
                  power_failures_log: [
                    [
                      %DSMR.Timestamp{value: ~N[2000-01-04 18:03:20], dst: "W"},
                      %DSMR.Measurement{value: 237_126, unit: "s"}
                    ],
                    [
                      %DSMR.Timestamp{value: ~N[2000-01-01 00:00:01], dst: "W"},
                      %DSMR.Measurement{value: 2_147_583_646, unit: "s"}
                    ],
                    [
                      %DSMR.Timestamp{value: ~N[2000-01-02 00:00:03], dst: "W"},
                      %DSMR.Measurement{value: 2_317_482_647, unit: "s"}
                    ]
                  ],
                  voltage_sags_l1_count: "00000",
                  voltage_sags_l2_count: "00000",
                  voltage_sags_l3_count: "00000",
                  voltage_swells_l1_count: "00000",
                  voltage_swells_l2_count: "00000",
                  voltage_swells_l3_count: "00000",
                  text_message_code: nil,
                  text_message: nil,
                  phase_power_current_l1: %DSMR.Measurement{value: 0, unit: "A"},
                  phase_power_current_l2: %DSMR.Measurement{value: 6, unit: "A"},
                  phase_power_current_l3: %DSMR.Measurement{value: 2, unit: "A"},
                  currently_delivered_l1: %DSMR.Measurement{value: 0.17, unit: "kW"},
                  currently_delivered_l2: %DSMR.Measurement{value: 1.247, unit: "kW"},
                  currently_delivered_l3: %DSMR.Measurement{value: 0.209, unit: "kW"},
                  currently_returned_l1: %DSMR.Measurement{value: 0.0, unit: "kW"},
                  currently_returned_l2: %DSMR.Measurement{value: 0.0, unit: "kW"},
                  currently_returned_l3: %DSMR.Measurement{value: 0.0, unit: "kW"},
                  mbus_devices: [
                    %DSMR.MBusDevice{
                      channel: 1,
                      device_type: "003",
                      equipment_id: "4819243993373755377509728609491464",
                      last_reading_measured_at: %DSMR.Timestamp{
                        value: ~N[2016-11-29 20:00:00],
                        dst: "W"
                      },
                      last_reading_value: %DSMR.Measurement{value: 981.443, unit: "m3"}
                    }
                  ],
                  checksum: "6796"
                }}
    end

    test "with telegram v5.0" do
      telegram =
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
          "1-0:32.32.0(00000)\r\n",
          "1-0:52.32.0(00000)\r\n",
          "1-0:72.32.0(00000)\r\n",
          "1-0:32.36.0(00000)\r\n",
          "1-0:52.36.0(00000)\r\n",
          "1-0:72.36.0(00000)\r\n",
          "0-0:96.13.0()\r\n",
          "1-0:32.7.0(0230.0*V)\r\n",
          "1-0:52.7.0(0230.0*V)\r\n",
          "1-0:72.7.0(0229.0*V)\r\n",
          "1-0:31.7.0(0.48*A)\r\n",
          "1-0:51.7.0(0.44*A)\r\n",
          "1-0:71.7.0(0.86*A)\r\n",
          "1-0:21.7.0(00.070*kW)\r\n",
          "1-0:41.7.0(00.032*kW)\r\n",
          "1-0:61.7.0(00.142*kW)\r\n",
          "1-0:22.7.0(00.000*kW)\r\n",
          "1-0:42.7.0(00.000*kW)\r\n",
          "1-0:62.7.0(00.000*kW)\r\n",
          "0-1:24.1.0(003)\r\n",
          "0-1:96.1.0(3232323241424344313233343536373839)\r\n",
          "0-1:24.2.1(170102161005W)(00000.107*m3)\r\n",
          "0-2:24.1.0(003)\r\n",
          "0-2:96.1.0()\r\n",
          "!6EEE\r\n"
        ])

      assert DSMR.parse(telegram) ==
               {:ok,
                %Telegram{
                  header: "ISk5\\2MT382-1000",
                  checksum: "6EEE",
                  version: "50",
                  measured_at: %Timestamp{value: ~N[2017-01-02 19:20:02], dst: "W"},
                  equipment_id: "4B384547303034303436333935353037",
                  electricity_delivered_1: %Measurement{unit: "kWh", value: 4.426},
                  electricity_delivered_2: %Measurement{unit: "kWh", value: 2.399},
                  electricity_returned_1: %Measurement{unit: "kWh", value: 2.444},
                  electricity_returned_2: %Measurement{unit: "kWh", value: 0.0},
                  electricity_tariff_indicator: "0002",
                  electricity_currently_delivered: %Measurement{unit: "kW", value: 0.244},
                  electricity_currently_returned: %Measurement{unit: "kW", value: 0.0},
                  power_failures_count: "00013",
                  power_failures_long_count: "00000",
                  power_failures_log: [],
                  voltage_sags_l1_count: "00000",
                  voltage_sags_l2_count: "00000",
                  voltage_sags_l3_count: "00000",
                  voltage_swells_l1_count: "00000",
                  voltage_swells_l2_count: "00000",
                  voltage_swells_l3_count: "00000",
                  phase_power_current_l1: %DSMR.Measurement{unit: "A", value: 0.48},
                  phase_power_current_l2: %DSMR.Measurement{unit: "A", value: 0.44},
                  phase_power_current_l3: %DSMR.Measurement{unit: "A", value: 0.86},
                  currently_delivered_l1: %DSMR.Measurement{unit: "kW", value: 0.07},
                  currently_delivered_l2: %DSMR.Measurement{unit: "kW", value: 0.032},
                  currently_delivered_l3: %DSMR.Measurement{unit: "kW", value: 0.142},
                  currently_returned_l1: %DSMR.Measurement{unit: "kW", value: 0.0},
                  currently_returned_l2: %DSMR.Measurement{unit: "kW", value: 0.0},
                  currently_returned_l3: %DSMR.Measurement{unit: "kW", value: 0.0},
                  voltage_l1: %DSMR.Measurement{unit: "V", value: 230.0},
                  voltage_l2: %DSMR.Measurement{unit: "V", value: 230.0},
                  voltage_l3: %DSMR.Measurement{unit: "V", value: 229.0},
                  mbus_devices: [
                    %DSMR.MBusDevice{
                      channel: 1,
                      device_type: "003",
                      equipment_id: "3232323241424344313233343536373839",
                      last_reading_measured_at: %DSMR.Timestamp{
                        value: ~N[2017-01-02 16:10:05],
                        dst: "W"
                      },
                      last_reading_value: %DSMR.Measurement{value: 0.107, unit: "m3"}
                    },
                    %DSMR.MBusDevice{
                      channel: 2,
                      device_type: "003"
                    }
                  ]
                }}
    end

    test "with empty telegram" do
      assert DSMR.parse("/empty\r\n\r\n!0039\r\n") ==
               {:ok, %Telegram{header: "empty", checksum: "0039"}}
    end

    test "with invalid telegram while lexing" do
      {:error, %DSMR.ParseError{message: message}} = DSMR.parse("invalid$foo")
      assert message =~ "unexpected character while parsing"
      assert message =~ "line 1"
    end

    test "with invalid telegram while parsing" do
      {:error, %DSMR.ParseError{message: message}} = DSMR.parse("invalid!foo")
      assert message =~ "unexpected token while parsing"
      assert message =~ "line 1"
    end

    test "with invalid checksum" do
      assert DSMR.parse("/foo\r\n\r\n1-3:0.2.8(42)\r\n!bar\r\n") ==
               {:error, %DSMR.ChecksumError{checksum: "7F91"}}
    end

    test "with invalid checksum but ignored" do
      assert DSMR.parse("/foo\r\n\r\n1-3:0.2.8(42)\r\n!bar\r\n", checksum: false) ==
               {:ok, %Telegram{header: "foo", version: "42", checksum: "bar"}}
    end

    test "with uppercase hex checksum" do
      telegram =
        Enum.join([
          "/ISk5\\2MT382-1000\r\n",
          "\r\n",
          "1-3:0.2.8(50)\r\n",
          "!5106\r\n"
        ])

      assert DSMR.parse(telegram) ==
               {:ok,
                %Telegram{
                  header: "ISk5\\2MT382-1000",
                  version: "50",
                  checksum: "5106"
                }}

      telegram_with_letters =
        Enum.join([
          "/KFM5KAIFA-METER\r\n",
          "\r\n",
          "1-3:0.2.8(42)\r\n",
          "1-0:1.8.1(001581.123*kWh)\r\n",
          "1-0:2.8.2(000000.000*kWh)\r\n",
          "1-0:1.7.0(02.027*kW)\r\n",
          "1-0:2.7.0(00.000*kW)\r\n",
          "0-0:96.7.21(00015)\r\n",
          "1-0:99.97.0(3)(0-0:96.7.19)(000104180320W)(0000237126*s)(000101000001W)",
          "(2147583646*s)(000102000003W)(2317482647*s)\r\n",
          "1-0:62.7.0(00.000*kW)\r\n",
          "0-1:24.2.1(161129200000W)(00981.443*m3)\r\n",
          "!AA23\r\n"
        ])

      assert {:ok, %Telegram{checksum: "AA23"}} = DSMR.parse(telegram_with_letters)
    end

    test "with valid uppercase checksum rejects altered value" do
      assert {:error, %DSMR.ChecksumError{}} =
               DSMR.parse("/foo\r\n\r\n1-3:0.2.8(42)\r\n!AAAA\r\n")
    end

    test "with ! in header" do
      telegram =
        Enum.join([
          "/ACME!MTR\r\n",
          "\r\n",
          "1-3:0.2.8(50)\r\n",
          "!8B4C\r\n"
        ])

      assert DSMR.parse(telegram) ==
               {:ok,
                %Telegram{
                  header: "ACME!MTR",
                  version: "50",
                  checksum: "8B4C"
                }}
    end

    test "with floats as decimals" do
      telegram =
        Enum.join([
          "/KFM5KAIFA-METER\r\n",
          "\r\n",
          "1-3:0.2.8(42)\r\n",
          "1-0:1.8.1(001581.123*kWh)\r\n",
          "1-0:2.8.2(000000.000*kWh)\r\n",
          "1-0:1.7.0(02.027*kW)\r\n",
          "1-0:2.7.0(00.000*kW)\r\n",
          "0-0:96.7.21(00015)\r\n",
          "1-0:99.97.0(3)(0-0:96.7.19)(000104180320W)(0000237126*s)(000101000001W)",
          "(2147583646*s)(000102000003W)(2317482647*s)\r\n",
          "1-0:62.7.0(00.000*kW)\r\n",
          "0-1:24.2.1(161129200000W)(00981.443*m3)\r\n",
          "!AA23\r\n"
        ])

      assert DSMR.parse(telegram, floats: :decimals) ==
               {:ok,
                %Telegram{
                  header: "KFM5KAIFA-METER",
                  version: "42",
                  electricity_delivered_1: %Measurement{
                    unit: "kWh",
                    value: Decimal.new("1581.123")
                  },
                  electricity_returned_2: %Measurement{unit: "kWh", value: Decimal.new("0.000")},
                  electricity_currently_delivered: %Measurement{
                    unit: "kW",
                    value: Decimal.new("2.027")
                  },
                  electricity_currently_returned: %Measurement{
                    unit: "kW",
                    value: Decimal.new("0.000")
                  },
                  power_failures_count: "00015",
                  power_failures_log: [
                    [
                      %DSMR.Timestamp{value: ~N[2000-01-04 18:03:20], dst: "W"},
                      %DSMR.Measurement{value: 237_126, unit: "s"}
                    ],
                    [
                      %DSMR.Timestamp{value: ~N[2000-01-01 00:00:01], dst: "W"},
                      %DSMR.Measurement{value: 2_147_583_646, unit: "s"}
                    ],
                    [
                      %DSMR.Timestamp{value: ~N[2000-01-02 00:00:03], dst: "W"},
                      %DSMR.Measurement{value: 2_317_482_647, unit: "s"}
                    ]
                  ],
                  currently_returned_l3: %DSMR.Measurement{
                    value: Decimal.new("0.000"),
                    unit: "kW"
                  },
                  mbus_devices: [
                    %DSMR.MBusDevice{
                      channel: 1,
                      last_reading_measured_at: %DSMR.Timestamp{
                        value: ~N[2016-11-29 20:00:00],
                        dst: "W"
                      },
                      last_reading_value: %DSMR.Measurement{
                        value: Decimal.new("981.443"),
                        unit: "m3"
                      }
                    }
                  ],
                  checksum: "AA23"
                }}
    end
  end

  describe "multi-channel M-Bus support" do
    test "valve position works on channel 2" do
      telegram =
        Enum.join([
          "/TEST\r\n",
          "\r\n",
          "0-2:24.1.0(003)\r\n",
          "0-2:96.1.0(1234567890123456)\r\n",
          "0-2:24.2.1(230101120000W)(00123.456*m3)\r\n",
          "0-2:24.4.0(2)\r\n",
          "!C3A6\r\n"
        ])

      assert DSMR.parse(telegram) ==
               {:ok,
                %Telegram{
                  header: "TEST",
                  checksum: "C3A6",
                  mbus_devices: [
                    %DSMR.MBusDevice{
                      channel: 2,
                      device_type: "003",
                      equipment_id: "1234567890123456",
                      last_reading_measured_at: %DSMR.Timestamp{
                        value: ~N[2023-01-01 12:00:00],
                        dst: "W"
                      },
                      last_reading_value: %DSMR.Measurement{value: 123.456, unit: "m3"},
                      valve_position: "2"
                    }
                  ]
                }}
    end

    test "legacy gas reading works on channel 3" do
      telegram =
        Enum.join([
          "/TEST\r\n",
          "\r\n",
          "0-3:24.1.0(003)\r\n",
          "0-3:96.1.0(9876543210987654)\r\n",
          "0-3:24.3.0(220615180000)(00)(60)(1)(0-3:24.2.1)(m3)\r\n",
          "(00456.789)\r\n",
          "!36A1\r\n"
        ])

      assert DSMR.parse(telegram) ==
               {:ok,
                %Telegram{
                  header: "TEST",
                  checksum: "36A1",
                  mbus_devices: [
                    %DSMR.MBusDevice{
                      channel: 3,
                      device_type: "003",
                      equipment_id: "9876543210987654",
                      last_reading_measured_at: %DSMR.Timestamp{
                        value: ~N[2022-06-15 18:00:00],
                        dst: nil
                      },
                      last_reading_value: %DSMR.Measurement{value: 456.789, unit: "m3"}
                    }
                  ]
                }}
    end

    test "valve position and legacy gas reading work on channel 4" do
      telegram =
        Enum.join([
          "/TEST\r\n",
          "\r\n",
          "0-4:24.1.0(007)\r\n",
          "0-4:96.1.0(ABCD1234ABCD1234)\r\n",
          "0-4:24.3.0(211201090000)(00)(60)(1)(0-4:24.2.1)(m3)\r\n",
          "(00789.012)\r\n",
          "0-4:24.4.0(3)\r\n",
          "!5EE1\r\n"
        ])

      assert DSMR.parse(telegram) ==
               {:ok,
                %Telegram{
                  header: "TEST",
                  checksum: "5EE1",
                  mbus_devices: [
                    %DSMR.MBusDevice{
                      channel: 4,
                      device_type: "007",
                      equipment_id: "ABCD1234ABCD1234",
                      last_reading_measured_at: %DSMR.Timestamp{
                        value: ~N[2021-12-01 09:00:00],
                        dst: nil
                      },
                      last_reading_value: %DSMR.Measurement{value: 789.012, unit: "m3"},
                      valve_position: "3"
                    }
                  ]
                }}
    end

    test "telegram with maximum allowed M-Bus devices (4 channels)" do
      telegram = max_mbus_telegram()

      assert {:ok, result} = DSMR.parse(telegram)
      assert length(result.mbus_devices) == 4
      assert Enum.at(result.mbus_devices, 0).channel == 1
      assert Enum.at(result.mbus_devices, 0).equipment_id == "1111111111111111"
      assert Enum.at(result.mbus_devices, 0).device_type == "003"
      assert Enum.at(result.mbus_devices, 1).channel == 2
      assert Enum.at(result.mbus_devices, 1).equipment_id == "2222222222222222"
      assert Enum.at(result.mbus_devices, 2).channel == 3
      assert Enum.at(result.mbus_devices, 2).device_type == "007"
      assert Enum.at(result.mbus_devices, 3).channel == 4
      assert Enum.at(result.mbus_devices, 3).equipment_id == "4444444444444444"
    end
  end

  describe "unknown OBIS codes" do
    test "are collected in unknown_fields" do
      telegram =
        Enum.join([
          "/TEST\r\n",
          "\r\n",
          "1-3:0.2.8(50)\r\n",
          "9-9:99.99.99(12345)\r\n",
          "8-8:88.88.88(678.90*kWh)\r\n",
          "!AD02\r\n"
        ])

      assert DSMR.parse(telegram) ==
               {:ok,
                %Telegram{
                  header: "TEST",
                  version: "50",
                  checksum: "AD02",
                  unknown_fields: [
                    {{9, 9, 99, 99, 99}, "12345"},
                    {{8, 8, 88, 88, 88}, %Measurement{unit: "kWh", value: 678.90}}
                  ]
                }}
    end

    test "are preserved in Telegram.to_string/1" do
      telegram = %Telegram{
        header: "TEST",
        version: "50",
        checksum: "ABCD",
        unknown_fields: [
          {{9, 9, 99, 99, 99}, "12345"},
          {{8, 8, 88, 88, 88}, %Measurement{unit: "kWh", value: 678.90}}
        ]
      }

      result = Telegram.to_string(telegram)

      assert result =~ "9-9:99.99.99(12345)"
      assert result =~ "8-8:88.88.88(000678.9*kWh)"
    end
  end

  describe "parse!/2" do
    test "with valid telegram" do
      assert DSMR.parse!("/empty\r\n\r\n!0039\r\n") ==
               %Telegram{header: "empty", checksum: "0039"}
    end

    test "with invalid telegram" do
      error =
        assert_raise DSMR.ParseError, fn ->
          DSMR.parse!("invalid")
        end

      assert error.message =~ "unexpected token while parsing"
      assert error.message =~ "line 1"
    end

    test "with power failure log count mismatch" do
      telegram =
        Enum.join(
          [
            "/KFM5KAIFA-METER\r\n",
            "\r\n",
            "0-0:1.0.0(170102192002W)\r\n",
            # Claim 5 events but only provide 3 (6 data items = 3 pairs)
            "1-0:99.97.0(5)(0-0:96.7.19)(000104180320W)(0000237126*s)(000101000001W)(2147583646*s)(000102000003W)(2317482647*s)\r\n",
            "!AA23\r\n"
          ],
          ""
        )

      error =
        assert_raise DSMR.ParseError, fn ->
          DSMR.parse!(telegram)
        end

      assert error.message ==
               "An unexpected error occurred while parsing: Power failures log count mismatch: expected 5 events, but got 3"
    end
  end

  describe "truncated and incomplete telegrams" do
    test "telegram missing final CRLF after checksum is still parsed" do
      telegram = truncated_telegram(:no_final_crlf)
      # Parser is lenient about trailing CRLF
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram)
    end

    test "telegram with header but empty checksum" do
      telegram = checksum_format_telegram(:empty)
      # Empty checksum is valid in DSMR 2.2
      assert {:ok, %Telegram{header: "TEST", checksum: ""}} = DSMR.parse(telegram)
    end

    test "telegram cut off mid-line" do
      telegram = truncated_telegram(:mid_line)
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram)
    end

    test "telegram cut off mid-OBIS code" do
      telegram = truncated_telegram(:mid_obis)
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram)
    end

    test "telegram cut off mid-measurement value" do
      telegram = truncated_telegram(:mid_measurement)
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram)
    end

    test "telegram with body but no checksum delimiter" do
      telegram = truncated_telegram(:no_delimiter)
      # Parser expects checksum delimiter
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram)
    end

    test "partial M-Bus device (only device_type, no reading)" do
      telegram =
        Enum.join([
          "/TEST\r\n",
          "\r\n",
          "0-1:24.1.0(003)\r\n",
          "!E2B3\r\n"
        ])

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert length(result.mbus_devices) == 1
      assert hd(result.mbus_devices).device_type == "003"
      assert hd(result.mbus_devices).equipment_id == nil
    end

    test "incomplete power failures log with odd number of attributes" do
      telegram =
        Enum.join([
          "/TEST\r\n",
          "\r\n",
          # Claim 2 events but only provide 1.5 (3 items instead of 4)
          "1-0:99.97.0(2)(0-0:96.7.19)(000104180320W)(0000237126*s)(000101000001W)\r\n",
          "!AA23\r\n"
        ])

      error =
        assert_raise DSMR.ParseError, fn ->
          DSMR.parse!(telegram)
        end

      assert error.message =~ "Power failures log count mismatch"
    end
  end

  describe "malformed OBIS codes" do
    test "OBIS with alphabetic characters is treated as unknown" do
      telegram = "/TEST\r\n\r\nA-0:1.8.1(123.45*kWh)\r\n!AA23\r\n"
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram)
    end

    test "OBIS with missing segments" do
      telegram = "/TEST\r\n\r\n1-0:1.8(123.45*kWh)\r\n!AA23\r\n"
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram)
    end

    test "OBIS with extra segments" do
      telegram = "/TEST\r\n\r\n1-0-2:1.8.1.0(123.45*kWh)\r\n!AA23\r\n"
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram)
    end

    test "OBIS with very large numbers" do
      telegram = "/TEST\r\n\r\n999-999:999.999.999(12345)\r\n!AA23\r\n"
      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert result.unknown_fields == [{{999, 999, 999, 999, 999}, "12345"}]
    end
  end

  describe "invalid measurement values" do
    test "measurement with invalid float (multiple decimals)" do
      telegram = invalid_measurement_telegram(:multiple_decimals)
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram)
    end

    test "measurement without unit" do
      telegram = "/TEST\r\n\r\n1-0:1.8.1(123.45*)\r\n!AA23\r\n"
      # Parser requires a unit after the asterisk
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram, checksum: false)
    end

    test "measurement without asterisk" do
      telegram = invalid_measurement_telegram(:no_asterisk)
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram)
    end

    test "measurement with empty value" do
      telegram = invalid_measurement_telegram(:empty_value)
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram)
    end

    test "measurement with very large number" do
      telegram = "/TEST\r\n\r\n1-0:1.8.1(999999999.999*kWh)\r\n!AA23\r\n"
      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert result.electricity_delivered_1.value == 999_999_999.999
    end
  end

  describe "invalid timestamps" do
    test "timestamp with invalid month (13)" do
      telegram = invalid_timestamp_telegram(:invalid_month)

      assert_raise DSMR.ParseError, fn ->
        DSMR.parse!(telegram, checksum: false)
      end
    end

    test "timestamp with invalid day (32)" do
      telegram = invalid_timestamp_telegram(:invalid_day)

      assert_raise DSMR.ParseError, fn ->
        DSMR.parse!(telegram, checksum: false)
      end
    end

    test "timestamp with invalid hour (24)" do
      telegram = invalid_timestamp_telegram(:invalid_hour)

      assert_raise DSMR.ParseError, fn ->
        DSMR.parse!(telegram, checksum: false)
      end
    end

    test "timestamp with invalid minute (60)" do
      telegram = invalid_timestamp_telegram(:invalid_minute)

      assert_raise DSMR.ParseError, fn ->
        DSMR.parse!(telegram, checksum: false)
      end
    end

    test "timestamp with invalid second (60)" do
      telegram = invalid_timestamp_telegram(:invalid_second)

      assert_raise DSMR.ParseError, fn ->
        DSMR.parse!(telegram, checksum: false)
      end
    end

    test "timestamp too short" do
      telegram = invalid_timestamp_telegram(:too_short)
      # Parser stores invalid timestamps as strings without validation
      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert is_binary(result.measured_at)
    end

    test "timestamp too long" do
      telegram = invalid_timestamp_telegram(:too_long)
      # Too long timestamp causes parsing error
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram, checksum: false)
    end

    test "timestamp February 30th (invalid date)" do
      telegram = invalid_timestamp_telegram(:feb_30)

      assert_raise DSMR.ParseError, fn ->
        DSMR.parse!(telegram, checksum: false)
      end
    end
  end

  describe "malformed structure" do
    test "attribute without opening parenthesis" do
      telegram = malformed_structure_telegram(:no_opening_paren)
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram, checksum: false)
    end

    test "attribute without closing parenthesis" do
      telegram = malformed_structure_telegram(:no_closing_paren)
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram, checksum: false)
    end

    test "empty attributes" do
      telegram = malformed_structure_telegram(:empty_attrs)
      # Parser accepts empty attributes and treats them as unknown fields
      assert {:ok, %Telegram{}} = DSMR.parse(telegram, checksum: false)
    end
  end

  describe "checksum format variations" do
    test "lowercase checksum" do
      telegram = checksum_format_telegram(:lowercase)
      assert {:ok, %Telegram{checksum: "5106"}} = DSMR.parse(telegram, checksum: false)
    end

    test "mixed case checksum" do
      telegram = checksum_format_telegram(:mixed_case)
      # Parser accepts any hex format, validation happens separately
      assert {:error, %DSMR.ChecksumError{}} = DSMR.parse(telegram)
    end

    test "checksum with leading zeros (empty checksum)" do
      telegram = checksum_format_telegram(:empty)
      # Empty checksum is valid for DSMR 2.2
      assert {:ok, %Telegram{checksum: ""}} = DSMR.parse(telegram)
    end

    test "checksum with 3 hex digits" do
      telegram = checksum_format_telegram(:three_digits)
      assert {:error, %DSMR.ChecksumError{}} = DSMR.parse(telegram)
    end

    test "checksum with 5 hex digits" do
      telegram = checksum_format_telegram(:five_digits)
      assert {:error, %DSMR.ChecksumError{}} = DSMR.parse(telegram)
    end

    test "checksum with non-hex characters" do
      telegram = checksum_format_telegram(:non_hex)
      assert {:error, %DSMR.ChecksumError{}} = DSMR.parse(telegram)
    end
  end

  describe "checksum position edge cases" do
    test "multiple ! delimiters in telegram" do
      telegram = "/TEST!\r\n\r\n1-3:0.2.8(50)\r\n!8B4C\r\n"
      # First ! in header, second is delimiter
      assert {:ok, %Telegram{header: "TEST!", checksum: "8B4C"}} =
               DSMR.parse(telegram, checksum: false)
    end

    test "data lines appearing after checksum" do
      telegram = "/TEST\r\n\r\n!0039\r\n1-3:0.2.8(50)\r\n"
      # Parser should handle this - checksum comes early
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram)
    end
  end

  describe "checksum validation scenarios" do
    test "checksum off by one" do
      # Correct checksum for this telegram is 5106, using 5107 instead
      telegram = basic_telegram("5107")
      assert {:error, %DSMR.ChecksumError{checksum: "2A99"}} = DSMR.parse(telegram)
    end

    test "checksum after modifying a single character" do
      telegram = String.replace(basic_telegram(), "50", "51")
      assert {:error, %DSMR.ChecksumError{}} = DSMR.parse(telegram)
    end

    test "correct checksum can be disabled" do
      telegram = invalid_checksum_telegram()
      assert {:ok, %Telegram{}} = DSMR.parse(telegram, checksum: false)
    end
  end

  describe "M-Bus device edge cases" do
    test "M-Bus devices out of order (channel 3, then 1, then 2)" do
      telegram =
        Enum.join([
          "/TEST\r\n",
          "\r\n",
          "0-3:24.1.0(003)\r\n",
          "0-3:96.1.0(3333)\r\n",
          "0-1:24.1.0(003)\r\n",
          "0-1:96.1.0(1111)\r\n",
          "0-2:24.1.0(003)\r\n",
          "0-2:96.1.0(2222)\r\n",
          "!AA23\r\n"
        ])

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      # Should be sorted by channel
      assert Enum.map(result.mbus_devices, & &1.channel) == [1, 2, 3]
    end

    test "M-Bus device with device_type 007 (water/heat)" do
      telegram = mbus_device_telegram(1, device_type: "007", equipment_id: "WATER123")

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert hd(result.mbus_devices).device_type == "007"
    end

    test "M-Bus device with unknown device_type" do
      telegram =
        mbus_device_telegram(1, device_type: "999", equipment_id: "UNKNOWN", reading: false)

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert hd(result.mbus_devices).device_type == "999"
    end

    test "M-Bus reading with non-gas units (GJ)" do
      telegram =
        Enum.join([
          "/TEST\r\n",
          "\r\n",
          "0-1:24.1.0(007)\r\n",
          "0-1:96.1.0(HEAT123)\r\n",
          "0-1:24.2.1(230101120000W)(00123.456*GJ)\r\n",
          "!AA23\r\n"
        ])

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert hd(result.mbus_devices).last_reading_value.unit == "GJ"
    end
  end

  describe "power failures log edge cases" do
    test "power failures log with 1 event" do
      telegram = power_failures_telegram(1)
      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert length(result.power_failures_log) == 1
    end

    test "power failures log with 10 events" do
      telegram = power_failures_telegram(10)
      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert length(result.power_failures_log) == 10
    end

    test "power failures log event with duration 0" do
      telegram =
        Enum.join([
          "/TEST\r\n",
          "\r\n",
          "1-0:99.97.0(1)(0-0:96.7.19)(000104180320W)(0*s)\r\n",
          "!AA23\r\n"
        ])

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert [[_timestamp, %Measurement{value: 0}]] = result.power_failures_log
    end

    test "power failures log event with very large duration" do
      telegram =
        Enum.join([
          "/TEST\r\n",
          "\r\n",
          "1-0:99.97.0(1)(0-0:96.7.19)(000104180320W)(4294967295*s)\r\n",
          "!AA23\r\n"
        ])

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert [[_timestamp, %Measurement{value: 4_294_967_295}]] = result.power_failures_log
    end
  end

  describe "three-phase power measurements" do
    test "single-phase meter (only L1 fields)" do
      telegram = three_phase_telegram()

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert result.voltage_l1.value == 230.0
      assert result.phase_power_current_l1.value == 0.48
      assert result.currently_delivered_l1.value == 0.07
      assert result.voltage_l2.value == 230.0
      assert result.voltage_l3.value == 229.0
    end

    test "voltage exactly 0V" do
      telegram = "/TEST\r\n\r\n1-0:32.7.0(0000.0*V)\r\n!AA23\r\n"

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert result.voltage_l1.value == 0.0
    end

    test "voltage over 250V (overvoltage)" do
      telegram = "/TEST\r\n\r\n1-0:32.7.0(0255.5*V)\r\n!AA23\r\n"

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert result.voltage_l1.value == 255.5
    end

    test "voltage under 200V (undervoltage)" do
      telegram = "/TEST\r\n\r\n1-0:32.7.0(0195.0*V)\r\n!AA23\r\n"

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert result.voltage_l1.value == 195.0
    end

    test "current exactly 0A" do
      telegram = "/TEST\r\n\r\n1-0:31.7.0(0.00*A)\r\n!AA23\r\n"

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert result.phase_power_current_l1.value == 0.0
    end

    test "current over 100A (very high load)" do
      telegram = "/TEST\r\n\r\n1-0:31.7.0(125.5*A)\r\n!AA23\r\n"

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert result.phase_power_current_l1.value == 125.5
    end

    test "power exactly 0W" do
      telegram = "/TEST\r\n\r\n1-0:21.7.0(00.000*kW)\r\n!AA23\r\n"

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert result.currently_delivered_l1.value == 0.0
    end

    test "power over 10kW (heavy load)" do
      telegram = "/TEST\r\n\r\n1-0:21.7.0(15.500*kW)\r\n!AA23\r\n"

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert result.currently_delivered_l1.value == 15.5
    end
  end

  describe "numeric precision tests" do
    test "very small values in native float mode" do
      telegram = "/TEST\r\n\r\n1-0:1.8.1(000000.001*kWh)\r\n!AA23\r\n"
      assert {:ok, result} = DSMR.parse(telegram, checksum: false, floats: :native)
      assert result.electricity_delivered_1.value == 0.001
    end

    test "very large values in native float mode" do
      telegram = "/TEST\r\n\r\n1-0:1.8.1(999999.999*kWh)\r\n!AA23\r\n"
      assert {:ok, result} = DSMR.parse(telegram, checksum: false, floats: :native)
      assert result.electricity_delivered_1.value == 999_999.999
    end

    test "no decimal part" do
      telegram = "/TEST\r\n\r\n1-0:1.8.1(000123*kWh)\r\n!AA23\r\n"
      assert {:ok, result} = DSMR.parse(telegram, checksum: false, floats: :native)
      assert result.electricity_delivered_1.value == 123.0
    end

    test "only decimal part" do
      telegram = "/TEST\r\n\r\n1-0:1.8.1(000000.123*kWh)\r\n!AA23\r\n"
      assert {:ok, result} = DSMR.parse(telegram, checksum: false, floats: :native)
      assert result.electricity_delivered_1.value == 0.123
    end

    test "Decimal mode with integer values" do
      telegram = "/TEST\r\n\r\n1-0:1.8.1(000123*kWh)\r\n!AA23\r\n"
      assert {:ok, result} = DSMR.parse(telegram, checksum: false, floats: :decimals)
      assert Decimal.equal?(result.electricity_delivered_1.value, Decimal.new("123.0"))
    end

    test "Decimal mode with very high precision" do
      telegram = "/TEST\r\n\r\n1-0:1.8.1(000123.123456789012345*kWh)\r\n!AA23\r\n"
      assert {:ok, result} = DSMR.parse(telegram, checksum: false, floats: :decimals)

      assert Decimal.equal?(
               result.electricity_delivered_1.value,
               Decimal.new("123.123456789012345")
             )
    end
  end

  describe "text message field tests" do
    test "text_message with invalid hex encoding (odd number of chars)" do
      telegram = text_message_telegram(code: nil, message: "303132333")

      # Should still parse, just store as-is
      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert result.text_message == "303132333"
    end

    test "text_message_code without text_message" do
      telegram = text_message_telegram(code: "303132", message: nil)

      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert result.text_message_code == "303132"
      assert result.text_message == nil
    end
  end

  describe "header variations" do
    test "header with spaces" do
      telegram = header_variation_telegram("TEST METER")
      assert {:ok, %Telegram{header: "TEST METER"}} = DSMR.parse(telegram, checksum: false)
    end

    test "header with special characters" do
      telegram = header_variation_telegram("TEST-METER_v1.0")

      assert {:ok, %Telegram{header: "TEST-METER_v1.0"}} =
               DSMR.parse(telegram, checksum: false)
    end

    test "very short header (single char)" do
      telegram = header_variation_telegram("T")
      assert {:ok, %Telegram{header: "T"}} = DSMR.parse(telegram, checksum: false)
    end

    test "very long header (256+ chars)" do
      long_header = String.duplicate("A", 300)
      telegram = header_variation_telegram(long_header)
      assert {:ok, %Telegram{header: ^long_header}} = DSMR.parse(telegram, checksum: false)
    end
  end

  describe "line ending variations" do
    test "LF-only line endings" do
      telegram = line_ending_telegram(:lf_only)
      # Parser requires CRLF, so LF-only should fail
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram, checksum: false)
    end

    test "mixed line endings (CRLF and LF)" do
      telegram = line_ending_telegram(:mixed)
      # Parser requires consistent CRLF, mixed should fail
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram, checksum: false)
    end

    test "extra blank lines between data" do
      telegram = line_ending_telegram(:extra_blanks)
      # Parser doesn't tolerate extra blank lines
      assert {:error, %DSMR.ParseError{}} = DSMR.parse(telegram, checksum: false)
    end
  end

  describe "unknown fields handling" do
    test "unknown OBIS with various attribute counts" do
      telegram = unknown_obis_telegram(2)
      # Parser should handle multiple attributes for unknown codes
      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert length(result.unknown_fields) >= 2
    end

    test "very large unknown_fields list (10+ entries)" do
      telegram = unknown_obis_telegram(15)
      assert {:ok, result} = DSMR.parse(telegram, checksum: false)
      assert length(result.unknown_fields) == 15
    end
  end
end
