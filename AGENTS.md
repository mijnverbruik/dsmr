# AGENTS.md

## Feature Evaluation: Question First, Plan Second

**CRITICAL**: Before diving into implementation planning, critically evaluate whether a feature is actually needed for this project's use case.

**Ask these questions FIRST**:
1. **What problem does this solve?** Be specific about the actual benefit.
2. **What is the context?** (e.g., localhost-only, production, development tool)
3. **What is the measurable impact?** Quantify the benefit (time saved, bytes reduced, errors prevented).
4. **Is the complexity justified?** Compare implementation cost vs. actual value delivered.

**Examples**:
- **Compression for localhost server**: Saves ~3ms per page load. Not worth the complexity.
- **Position tracking in parser errors**: Shows exact line/column for syntax errors. Worth the complexity—saves hours of debugging.
- **Validation in parser**: Catches errors earlier. Worth the complexity for better error messages.
- **Premature optimization**: "Might be useful later" is not justification. YAGNI applies.

**Process**:
1. User requests feature
2. **Before exploring or planning**, ask: "Is this actually valuable for [specific context]?"
3. If unclear, ask the user about their use case and constraints
4. If not valuable, explain why and suggest alternatives (or skip it entirely)
5. Only proceed with planning if the value is clear and justified

Don't waste time planning solutions to non-problems.

## Build & Test Commands

- **Test all**: `mix test`
- **Test single file**: `mix test test/dsmr_test.exs`
- **Test single case**: `mix test test/dsmr_test.exs:DSMRTest.parse/2`
- **Format code**: `mix format`
- **Type check**: `mix dialyzer`
- **Compile**: `mix compile`

## Architecture & Structure

**DSMR** is an Elixir library for parsing Dutch Smart Meter Requirements telegrams. Uses a **two-stage parsing architecture**:

- **Stage 1 (Lexer)**: `src/dsmr_lexer.xrl` - Tokenizes raw telegram data using leex
- **Stage 2 (Parser)**: `src/dsmr_parser.yrl` - Transforms tokens to `DSMR.Telegram` struct using yecc
- **Core modules** (`lib/dsmr/`): `parser.ex`, `obis.ex`, `telegram.ex`, `measurement.ex`, `crc16.ex`, `mbus_device.ex`, `timestamp.ex`
- **Key entry point**: `DSMR.parse(telegram, opts)` - Main parsing function
- **OBIS mapping**: `DSMR.OBIS` module is single source of truth for field-to-OBIS mappings
- **Directory**: `src/` (Erlang .xrl/.yrl), `lib/dsmr/` (Elixir), `test/support/` (fixtures)
- **OBIS format**: `"1-0:1.8.1"` → `[1,0,1,8,1]`; M-Bus wildcards: `"0-*:24.1.0"` (channel in pos 1)
- **Versions**: Supports DSMR v2.2, v3.0, v4.x, v5.x
- **Graceful handling**: Unknown OBIS codes collected in `telegram.unknown_fields`, not rejected

## Data Structures

- **`DSMR.Telegram`**: `header`, `checksum`, `version`, `measured_at`, `equipment_id`, `electricity_{delivered|returned}_{1|2}`, `electricity_{tariff_indicator|currently_{delivered|returned}}`, `voltage_l{1|2|3}`, `phase_power_current_l{1|2|3}`, `currently_{delivered|returned}_l{1|2|3}`, `power_failures_{count|long_count|log}`, `voltage_{sags|swells}_l{1|2|3}_count`, `actual_{threshold_electricity|switch_position}`, `text_message{|_code}`, `mbus_devices` (list), `unknown_fields` (list)
- **`DSMR.Measurement`**: `value` (float | Decimal), `unit` (string: "kWh", "kW", "V", "A", "m3", "s")
- **`DSMR.Timestamp`**: `value` (NaiveDateTime, 2000-2099 range), `dst` ("W" | "S" | nil)
- **`DSMR.MBusDevice`**: `channel` (1-4), `device_type`, `equipment_id`, `valve_position`, `last_reading_{value|measured_at}`

## Public API

- **`DSMR.parse(string, opts \\ [])`** → `{:ok, %Telegram{}}` | `{:error, %ParseError{}}` | `{:error, %ChecksumError{}}`
  - Options: `checksum: true|false` (default: true), `floats: :native|:decimals` (default: :native)
- **`DSMR.parse!(string, opts \\ [])`** → `%Telegram{}` | raises
- **`DSMR.Telegram.to_string(telegram)`** → binary (round-trip serialization)
- **`DSMR.OBIS.get_field(obis_list)`** → atom | nil (e.g., `[1,0,1,8,1]` → `:electricity_delivered_1`)
- **`DSMR.OBIS.get_obis(field)`** → string | nil (e.g., `:electricity_delivered_1` → `"1-0:1.8.1"`)
- **`DSMR.CRC16.checksum(input)`** → 4-char hex string (CRC-16-IBM/0xA001)

## Test Fixtures

Available in `TelegramFixtures` (`test/support/telegram_fixtures.ex`):

- **Valid**: `basic_telegram/1`, `max_mbus_telegram/0`, `three_phase_telegram/1`, `power_failures_telegram/1`, `text_message_telegram/1`, `unknown_obis_telegram/1`, `full_featured_telegram/0`, `dsmr_v{22|30|40}_telegram/0`
- **Errors**: `invalid_checksum_telegram/0`, `invalid_timestamp_telegram/1`, `invalid_measurement_telegram/1`, `truncated_telegram/1`, `malformed_structure_telegram/1`

## Code Style & Conventions

- **Language**: Elixir ~1.14
- **Format**: `mix format` (standard Elixir formatter)
- **Type checking**: Dialyzer (`mix dialyzer`)
- **Naming**: snake_case for functions/variables, PascalCase for modules; booleans suffixed with `?`
- **Patterns**: Use pattern matching, pipe operator (`|>`), guard clauses
- **Errors**: Return `{:ok, value}` / `{:error, reason}` tuples; exceptions for parse errors (`ParseError`, `ChecksumError`)
- **Imports**: Standard Elixir (no external runtime dependencies except optional `Decimal`). Compilers: `leex`, `yecc`
- **Tests**: ExUnit (async: true), use fixtures from `test/support/`
- **Documentation**: `@moduledoc` in every module, `@doc` for all public functions, use heredocs with markdown

## Additional Resources

- [Elixir Library Guidelines](https://hexdocs.pm/elixir/library-guidelines.html)
- [Elixir Anti Patterns](https://hexdocs.pm/elixir/what-anti-patterns.html)
- [Code-related Anti Patterns](https://hexdocs.pm/elixir/code-anti-patterns.html)
- [Design-related Anti Patterns](https://hexdocs.pm/elixir/design-anti-patterns.html)
- [Process-related Anti Patterns](https://hexdocs.pm/elixir/process-anti-patterns.html)
- [Meta-programming Anti Patterns](https://hexdocs.pm/elixir/macro-anti-patterns.html)
- [Naming Conventions](https://hexdocs.pm/elixir/naming-conventions.html)
