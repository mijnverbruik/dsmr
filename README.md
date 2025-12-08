# DSMR

[![Build Status](https://img.shields.io/github/actions/workflow/status/mijnverbruik/dsmr/test.yml?branch=main&style=flat-square)](https://github.com/mijnverbruik/dsmr/actions?query=workflow%3Atest)
[![Hex.pm](https://img.shields.io/hexpm/v/dsmr.svg?style=flat-square)](https://hex.pm/packages/dsmr)
[![Hexdocs.pm](https://img.shields.io/badge/hex-docs-blue.svg?style=flat-square)](https://hexdocs.pm/dsmr/)

<!-- MDOC !-->

A library for parsing Dutch Smart Meter Requirements (DSMR) telegram data.

DSMR is the standardized protocol used by smart energy meters in the Netherlands, Belgium, and Luxembourg. These smart meters are installed in homes and businesses to measure electricity and gas consumption in real-time.

Smart meters continuously broadcast "telegrams" - structured data packets containing:
- Current and cumulative electricity usage (delivered and returned to grid)
- Gas consumption readings
- Voltage and current measurements per phase
- Power failure logs and quality statistics
- Additional M-Bus connected devices (water, thermal, etc.)

This library parses these telegrams into Elixir structs, making it easy to build energy monitoring applications, home automation systems, or analytics dashboards.

## Installation

Add `dsmr` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dsmr, "~> 1.0"},
    {:decimal, "~> 2.0"} # Optional: Required only if you want to use floats: :decimals option for arbitrary precision
  ]
end
```

By default, measurement values are returned as native floats. To use high-precision `%Decimal{}` structs instead, add the [Decimal](https://hex.pm/packages/decimal) dependency and pass the `floats: :decimals` option to `DSMR.parse/2`.

## Supported DSMR Versions

This library supports **DSMR 4.x and 5.x** protocols:
- **DSMR 4.x** (version "42", "40") - Older Dutch meters
- **DSMR 5.x** (version "50") - Current standard in Netherlands, Belgium, Luxembourg

The parser automatically handles version differences. The `version` field in the telegram indicates which protocol version the meter uses.

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

### Parser Options

`DSMR.parse/2` accepts an optional keyword list of options:

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `:checksum` | `true` / `false` | `true` | When `false`, skips CRC16 checksum validation. Useful for testing or when processing telegrams from trusted sources. |
| `:floats` | `:native` / `:decimals` | `:native` | Controls numeric precision:<br>• `:native` - Uses Erlang's native float conversion (faster, may have rounding)<br>• `:decimals` - Returns `Decimal` structs for arbitrary precision (requires the `decimal` package) |

**Examples:**

```elixir
# Skip checksum validation
DSMR.parse(telegram, checksum: false)

# Use Decimal for precise calculations
DSMR.parse(telegram, floats: :decimals)

# Combine options
DSMR.parse(telegram, checksum: false, floats: :decimals)
```

### Available Telegram Fields

The parsed `%DSMR.Telegram{}` struct contains the following fields:

**Header & Metadata**
- `header` - Meter manufacturer and model
- `checksum` - CRC16 checksum
- `version` - DSMR protocol version ("42", "50", etc.)
- `measured_at` - Timestamp of measurement
- `equipment_id` - Unique meter identifier

**Electricity Measurements**
- `electricity_delivered_1` / `electricity_delivered_2` - Cumulative consumption (tariff 1/2)
- `electricity_returned_1` / `electricity_returned_2` - Cumulative return to grid (tariff 1/2)
- `electricity_tariff_indicator` - Current active tariff
- `electricity_currently_delivered` / `electricity_currently_returned` - Instantaneous power

**Per-Phase Measurements** (3-phase connections)
- `currently_delivered_l1/l2/l3` - Power delivered per phase
- `currently_returned_l1/l2/l3` - Power returned per phase
- `voltage_l1/l2/l3` - Voltage per phase
- `phase_power_current_l1/l2/l3` - Current per phase

**Power Quality**
- `power_failures_count` / `power_failures_long_count` - Failure counters
- `power_failures_log` - Timestamped log of power failures
- `voltage_sags_l1/l2/l3_count` / `voltage_swells_l1/l2/l3_count` - Quality events

**M-Bus Devices** (gas, water, thermal meters)
- `mbus_devices` - List of `%DSMR.MBusDevice{}` structs with gas/water/heat readings

When the parser encounters OBIS codes that aren't in its mapping table, they're collected in `unknown_fields` as `{obis_tuple, value}` pairs instead of causing a crash. This allows the library to handle:
- Proprietary meter-specific codes
- Newer OBIS codes not yet supported
- Regional variations in smart meter implementations

See [full documentation](https://hexdocs.pm/dsmr/DSMR.Telegram.html) for detailed field descriptions and types.

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

### Error Handling

The parser returns `{:error, reason}` tuples for invalid data:

```elixir
DSMR.parse("invalid data")
#=> {:error, {1, :dsmr_parser, ['syntax error before: ', []]}}

DSMR.parse("/HEADER\r\n!FFFF\r\n")  # Bad checksum
#=> {:error, :invalid_checksum}
```

**Common errors:**
- `:invalid_checksum` - CRC16 validation failed
- `{line, :dsmr_parser, message}` - Syntax error at specific line
- `{line, :dsmr_lexer, message}` - Tokenization error

**Troubleshooting:**
- Ensure telegrams are complete (start with `/`, end with `!` + checksum)
- Check for proper line endings (`\r\n`)
- Verify the telegram hasn't been corrupted during transmission
- Some meters send partial telegrams on connection - wait for the next complete one

### Getting Real Telegram Data

Smart meters typically expose data via:
- **Serial port** (P1 port, usually RJ12 or RJ11 connector, 115200 baud)
- **Network** (some meters or P1-to-WiFi adapters expose TCP sockets)

This library only handles parsing - you'll need to handle data acquisition separately.

**Example: Reading from a networked meter**

See the included [Livebook example](examples/connect_to_dsmr_meter.livemd) for a complete GenServer implementation that:
- Connects to a meter via TCP (common with WiFi P1 adapters)
- Buffers incoming lines and assembles complete telegrams
- Parses telegrams and visualizes real-time usage

For serial port connections, use libraries like [Circuits.UART](https://hex.pm/packages/circuits_uart).

## Internals

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

OBIS code mapping is centralized in the `DSMR.OBIS` Elixir module (`lib/dsmr/obis.ex`), which serves as the single source of truth for all field mappings. The parser calls this module at runtime to map OBIS codes like `[1,0,1,8,1]` to field names like `:electricity_delivered_1`.

Special cases are handled directly in the parser:
- **MBus devices**: Fields with wildcards (e.g., `0-*:24.1.0`) are grouped by channel
- **Power failures log**: Nested structure with variable-length event lists
- **Unknown OBIS codes**: Unrecognized codes are tagged and collected in `unknown_fields` rather than causing parse failures

The final `DSMR.Parser` module coordinates both stages and constructs the final struct with proper type conversions (Decimal, NaiveDateTime, etc.).

<!-- MDOC !-->

## Changelog

Please see [CHANGELOG](CHANGELOG.md) for more information on what has changed recently.

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/mijnverbruik/dsmr/issues)
- Fix bugs and [submit pull requests](https://github.com/mijnverbruik/dsmr/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

## License

Copyright (C) Robin van der Vleuten

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
