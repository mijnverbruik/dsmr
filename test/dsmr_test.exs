defmodule DSMRTest do
  use ExUnit.Case

  describe "parse/1" do
    test "parses DSMR v2.2 telegrams" do
      assert {:ok, result} = DSMR.parse(telegram_v2_2())
    end

    test "parses DSMR v3.0 telegrams" do
      assert {:ok, result} = DSMR.parse(telegram_v3_0())
    end

    test "parses DSMR v4.2 telegrams" do
      assert {:ok, result} = DSMR.parse(telegram_v4_2())
    end

    test "parses DSMR v5.0 telegrams" do
      assert {:ok, result} = DSMR.parse(telegram_v5_0())
    end

    test "returns a DSMR.ParseError when an invalid telegram is passed" do
      assert {:error, %DSMR.ParseError{}} = DSMR.parse("invalid")
    end
  end

  describe "parse!/1" do
    test "raises a DSMR.ParseError when an invalid telegram is passed" do
      assert_raise DSMR.ParseError, fn ->
        DSMR.parse!("invalid")
      end
    end
  end

  defp telegram_v2_2() do
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
  end

  defp telegram_v3_0() do
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
  end

  defp telegram_v4_2() do
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
  end

  defp telegram_v5_0() do
    Enum.join(
      [
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
      ],
      ""
    )
  end
end
