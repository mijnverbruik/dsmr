defmodule DSMR.CRC16 do
  @moduledoc false

  import Bitwise

  @polynomial 0xA001

  # Precompute the CRC for every possible byte value so that the per-byte
  # work at runtime is a single table lookup instead of eight shift/xor steps.
  @table (for byte <- 0..255 do
            Enum.reduce(1..8, byte, fn _, crc ->
              if (crc &&& 0x0001) > 0 do
                bxor(crc >>> 1, @polynomial)
              else
                crc >>> 1
              end
            end)
          end)
         |> List.to_tuple()

  def checksum(input) do
    update(0x0000, input)
    |> Integer.to_string(16)
    |> String.pad_leading(4, "0")
    |> String.upcase()
  end

  defp update(crc, <<>>), do: crc

  defp update(crc, <<c, b::binary>>) do
    crc = bxor(crc >>> 8, elem(@table, bxor(crc, c) &&& 0xFF))
    update(crc, b)
  end
end
