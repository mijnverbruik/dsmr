# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0](https://github.com/mijnverbruik/dsmr/compare/v0.6.0...v1.0.0) (2025-10-06)


### Features

- Centralizing OBIS attribute handling with lookup table
- Fix mbus channel ordering
- Surface parser errors with context
- Fix checksum validation to accept uppercase hex digits
- Fix checksum parsing crash when ! appears in header
- Move OBIS-to-field mapping from Elixir into yecc parser
- Extract MBus channel in lexer for single-pass processing
- Centralize OBIS mappings plus add Telegram.to_string
- Validate power failure log event count
- Extend M-Bus valve position and legacy gas reading to all channels
- Handle unknown OBIS codes gracefully
