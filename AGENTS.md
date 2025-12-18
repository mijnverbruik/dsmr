# AGENTS.md

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
