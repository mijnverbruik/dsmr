defmodule DSMRTest do
  use ExUnit.Case, async: true

  alias DSMR.{Measurement, Telegram, Timestamp}

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
end
