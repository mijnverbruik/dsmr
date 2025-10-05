# DSMR

[![Build Status](https://img.shields.io/github/actions/workflow/status/mijnverbruik/dsmr/test.yml?branch=main&style=flat-square)](https://github.com/mijnverbruik/dsmr/actions?query=workflow%3Atest)
[![Hex.pm](https://img.shields.io/hexpm/v/dsmr.svg?style=flat-square)](https://hex.pm/packages/dsmr)
[![Hexdocs.pm](https://img.shields.io/badge/hex-docs-blue.svg?style=flat-square)](https://hexdocs.pm/dsmr/)

<!-- MDOC !-->

A library for parsing Dutch Smart Meter Requirements (DSMR) telegram data.

## Usage

```elixir
telegram =
  # String is formatted in separate lines for readability.
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

DSMR.parse(telegram)
#=> {:ok, %DSMR.Telegram{header: "KFM5KAIFA-METER", version: "42", electricity_delivered_1: %Measurement{unit: "kWh",value: Decimal.new("1581.123")}, ...]}
```

### Serialization

You can convert a `Telegram` struct back to its string representation:

```elixir
telegram = %DSMR.Telegram{
  header: "KFM5KAIFA-METER",
  checksum: "6796",
  version: "42",
  measured_at: %DSMR.Timestamp{
    value: ~N[2016-11-13 20:57:57],
    dst: "W"
  },
  electricity_delivered_1: %DSMR.Measurement{value: Decimal.new("1581.123"), unit: "kWh"}
}

DSMR.Telegram.to_string(telegram)
#=> "/KFM5KAIFA-METER\r\n\r\n1-3:0.2.8(42)\r\n0-0:1.0.0(161113205757W)\r\n1-0:1.8.1(001581.123*kWh)\r\n!6796\r\n"
```

<!-- MDOC !-->

## How it Works

This library uses a two-stage parsing architecture built on Erlang's **leex** (lexical analyzer) and **yecc** (parser generator):

### Stage 1: Lexical Analysis (leex)

The lexer (`src/dsmr_lexer.xrl`) tokenizes raw DSMR telegram data into structured tokens:

- **OBIS codes**: Pattern `1-0:1.8.1` → `{obis, Line, {[1,0,1,8,1], Channel}}`
- **Timestamps**: Pattern `161113205757W` → `{timestamp, Line, {[16,11,13,20,57,57], "W"}}`
- **Measurements**: Float/int values like `001581.123` → `{float, Line, "001581.123"}`
- **Headers/Footers**: `/KFM5KAIFA-METER` and `!6796` → `{header, ...}` / `{checksum, ...}`

The lexer also extracts the MBus channel number from OBIS codes (second position) for single-pass processing of multi-device telegrams.

### Stage 2: Parsing (yecc)

The parser (`src/dsmr_parser.yrl`) uses grammar rules to transform tokens into the `DSMR.Telegram` struct:

```erlang
object -> obis attributes : map_obis_to_field('$1', '$2').
attribute -> '(' value ')' : '$2'.
value -> float '*' string : extract_measurement('$1', '$3').
```

OBIS code mapping is centralized in the `DSMR.OBIS` Elixir module, which serves as the single source of truth for all field mappings. The parser calls this module at runtime to map OBIS codes like `[1,0,1,8,1]` to field names like `:electricity_delivered_1`.

Special cases are handled directly in the parser:
- **MBus devices**: Fields with wildcards (e.g., `0-*:24.1.0`) are grouped by channel
- **Power failures log**: Nested structure with variable-length event lists

The final `DSMR.Parser` module coordinates both stages and constructs the final struct with proper type conversions (Decimal, NaiveDateTime, etc.).

See the [online documentation](https://hexdocs.pm/dsmr) for more information.

## Installation

Add `dsmr` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dsmr, "~> 0.6"}
  ]
end
```

## Changelog

Please see [CHANGELOG](CHANGELOG.md) for more information on what has changed recently.

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/mijnverbruik/dsmr/issues)
- Fix bugs and [submit pull requests](https://github.com/mijnverbruik/dsmr/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```
git clone https://github.com/mijnverbruik/dsmr.git
cd dsmr
mix test
```

## License

Copyright (C) 2020 Robin van der Vleuten

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
