defmodule DSMR.TelegramFixturesTest do
  use ExUnit.Case, async: true

  import DSMR.TelegramFixtures

  # Guards against fixture files losing their CRLF line endings or
  # checksums (e.g. through editor or git line-ending conversion).
  for path <- fixture_paths() do
    @path path

    test "#{Path.basename(path)} parses with a valid checksum" do
      assert {:ok, _telegram} = DSMR.parse(File.read!(@path))
    end
  end

  test "fixture files exist" do
    assert fixture_paths() != []
  end
end
