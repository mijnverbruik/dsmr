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
    {:decimal, "~> 3.1"} # Optional: Required only if you want to use floats: :decimals option for arbitrary precision
  ]
end
```

By default, measurement values are returned as native floats. To use high-precision `%Decimal{}` structs instead, add the [Decimal](https://hex.pm/packages/decimal) dependency and pass the `floats: :decimals` option to `DSMR.parse/2`.

## Supported DSMR Versions

The parser supports DSMR 2.2, 3.0, 4.x, and 5.x telegrams. Version-specific
fields are optional on `%DSMR.Telegram{}` and remain `nil` when they are not
present in the input.

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

{:ok, parsed} = DSMR.parse(telegram)

parsed.version
#=> "42"

parsed.electricity_delivered_1
#=> %DSMR.Measurement{unit: "kWh", value: 1581.123}
```

### Parser Options

`DSMR.parse/2` accepts these options:

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `:checksum` | `true` / `false` | `true` | Validates the CRC16 checksum when enabled. |
| `:floats` | `:native` / `:decimals` | `:native` | Returns decimal values as native floats or `%Decimal{}` structs. |

Examples:

```elixir
# Skip checksum validation
DSMR.parse(telegram, checksum: false)

# Tolerate common deviations from the standard (LF-only line endings,
# power failure log count mismatches) seen on real-world setups
DSMR.parse(data, lenient: true)

# Use Decimal for precise calculations
DSMR.parse(telegram, floats: :decimals)
```

### Available Telegram Fields

`DSMR.parse/2` returns a `%DSMR.Telegram{}` struct. Common fields include:

**Header and metadata**
- `header` - Meter manufacturer and model
- `checksum` - CRC16 checksum
- `version` - DSMR protocol version
- `measured_at` - Telegram timestamp
- `equipment_id` - Unique meter identifier

**Electricity measurements**
- `electricity_delivered_1` / `electricity_delivered_2` - Cumulative consumption (tariff 1/2)
- `electricity_returned_1` / `electricity_returned_2` - Cumulative return to grid (tariff 1/2)
- `electricity_tariff_indicator` - Current active tariff
- `electricity_currently_delivered` / `electricity_currently_returned` - Instantaneous power

**Per-phase measurements**
- `currently_delivered_l1/l2/l3` - Power delivered per phase
- `currently_returned_l1/l2/l3` - Power returned per phase
- `voltage_l1/l2/l3` - Voltage per phase
- `phase_power_current_l1/l2/l3` - Current per phase

**Power quality**
- `power_failures_count` / `power_failures_long_count` - Failure counters
- `power_failures_log` - Timestamped log of power failures
- `voltage_sags_l1/l2/l3_count` / `voltage_swells_l1/l2/l3_count` - Quality events

**M-Bus devices**
- `mbus_devices` - Connected gas, water, heat, or other meters

Unknown OBIS codes are collected in `unknown_fields` as `{obis_tuple, value}`
pairs. They are preserved instead of rejected.

See [full documentation](https://hexdocs.pm/dsmr/DSMR.Telegram.html) for detailed field descriptions and types.

### Decoding Values

Parsed telegrams keep values exactly as they appear in the telegram, so
serialization stays lossless. Two helpers decode them into more useful forms:

```elixir
# equipment_id, text_message, and M-Bus equipment ids are hex-encoded ASCII
DSMR.Telegram.decode_octet_string(parsed.equipment_id)
#=> {:ok, "K8EG004046395507"}

# Timestamps are Dutch local time; the DST marker gives the UTC offset
DSMR.Timestamp.to_datetime(parsed.measured_at)
#=> {:ok, ~U[2016-11-13 19:57:57Z]}
```

`to_datetime/1` returns `{:error, :missing_dst}` for timestamps without a DST
marker (DSMR 2.2/3.0), as their UTC offset is ambiguous.

### Serialization

Use `DSMR.Telegram.to_string/1` to convert a telegram struct back to its string
representation. Fields with `nil` or empty string values are omitted.

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

The parser returns `{:error, reason}` tuples for invalid data.

```elixir
DSMR.parse("invalid data")
#=> {:error, %DSMR.ParseError{message: "checksum delimiter '!' not found"}}

{:error, %DSMR.ChecksumError{}} = DSMR.parse("/HEADER\r\n!FFFF\r\n")
```

Use `DSMR.parse!/2` when invalid input should raise instead of returning an
error tuple.

### Getting Real Telegram Data

Smart meters typically expose telegram data through a serial P1 port or through
a P1-to-network adapter. This package only parses telegrams; collecting bytes
from the meter is handled separately.

See the included [Livebook example](examples/connect_to_dsmr_meter.livemd) for
a GenServer that:
- Connects to a meter via TCP (common with WiFi P1 adapters)
- Buffers incoming lines and assembles complete telegrams
- Parses telegrams and visualizes usage

For serial port connections, use libraries like [Circuits.UART](https://hex.pm/packages/circuits_uart).

## Internals

DSMR uses a two-stage parser built on Erlang's `leex` and `yecc`.

### Stage 1: Lexical Analysis (leex)

The lexer (`src/dsmr_lexer.xrl`) turns telegram text into tokens:

- OBIS codes such as `1-0:1.8.1`
- Timestamps such as `161113205757W`
- Measurements such as `001581.123*kWh`
- Headers and checksums

The lexer also extracts the M-Bus channel from OBIS codes.

### Stage 2: Parsing (yecc)

The parser (`src/dsmr_parser.yrl`) maps tokens into a `%DSMR.Telegram{}`:

```erlang
object -> obis attributes : map_obis_to_field('$1', '$2').
attribute -> '(' value ')' : '$2'.
value -> float '*' string : extract_measurement('$1', '$3').
```

OBIS mappings live in `DSMR.OBIS`. The parser calls that module to map known
codes to telegram fields.

Special cases are handled directly in the parser:
- M-Bus fields are grouped by channel.
- Power failure logs are parsed as variable-length event lists.
- Unknown OBIS codes are collected in `unknown_fields`.

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
