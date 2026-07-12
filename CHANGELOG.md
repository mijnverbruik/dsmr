# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0](https://github.com/mijnverbruik/dsmr/compare/v1.0.0...v1.1.0) (2026-07-11)


### Features

* add lenient parsing option for nonconforming meters ([133d5b6](https://github.com/mijnverbruik/dsmr/commit/133d5b6fb720b6d7a42f512eb5e28434e0f2065d))
* add timestamp-to-UTC and octet-string decoding helpers ([2637286](https://github.com/mijnverbruik/dsmr/commit/2637286a94b676137271ad52a93f89777a611a9c))
* include expected and actual checksum in error ([c583514](https://github.com/mijnverbruik/dsmr/commit/c583514e111860531870daf758a82148b60f5f5f))


### Bug Fixes

* descriptive error for malformed legacy gas reading ([27fc1eb](https://github.com/mijnverbruik/dsmr/commit/27fc1eb1d18d1f4aeb245b65b6ab868878207538))
* only include decimal code when decimal is loaded ([dc1c691](https://github.com/mijnverbruik/dsmr/commit/dc1c6910111d29c77ccc67955a64c0a6b4b41911))
* preserve precision for lossless round-trip ([6b03d84](https://github.com/mijnverbruik/dsmr/commit/6b03d848b00b42d5d784ad8d8e9b31ec41c8189a))
* reject timestamps that lack the DST marker ([a77d227](https://github.com/mijnverbruik/dsmr/commit/a77d2274e1125ec0dc4fa735a1c3379619defcb9))
* require checksum for telegrams that declare a DSMR version ([fd710fa](https://github.com/mijnverbruik/dsmr/commit/fd710fa7174afec0d9831cdeeaf123e4d139a967))
* return tagged error for malformed power failure log ([de58a43](https://github.com/mijnverbruik/dsmr/commit/de58a43cf8d14100dd3b4681e858730d8bb7c7bf))
* serialize hand-built measurements with spec-defined field widths ([70ec5eb](https://github.com/mijnverbruik/dsmr/commit/70ec5ebb3d604ae134f06eecad9dd485de0f079f))
* stop rescuing all exceptions as parse errors ([4927138](https://github.com/mijnverbruik/dsmr/commit/49271380ea2447cce8519fad46f1ec7eeede77ed))
* validate timestamp token length in lexer ([e496dd8](https://github.com/mijnverbruik/dsmr/commit/e496dd8620943d475fd0d238b505c06b8957cdf4))


### Performance Improvements

* compile OBIS lookups to O(1) function heads ([f964a95](https://github.com/mijnverbruik/dsmr/commit/f964a9527a7aca5e1e988a301bb17545dda2972b))
* move checksum validation before parsing for early rejection ([d51ad93](https://github.com/mijnverbruik/dsmr/commit/d51ad93b516554872d517c421b40f2d294ccf0dc))
* replace regex timestamp split with binary match ([4caf2d2](https://github.com/mijnverbruik/dsmr/commit/4caf2d27d1fe286c55405624362d33a5ba35922f))
* use compile-time lookup table for CRC16 checksum ([faaeee8](https://github.com/mijnverbruik/dsmr/commit/faaeee8773e3126bc2ddd409000ae1e4e1172959))
* validate checksum in single pass via lexer token ([a447d30](https://github.com/mijnverbruik/dsmr/commit/a447d305230636d18cca8b04fcc6754bded6ba18))

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
