defmodule DSMR.CRC16 do
  @moduledoc false

  import Bitwise

  @polynomial 0xA001

  def checksum(input) do
    update(0x0000, input)
    |> Integer.to_string(16)
    |> String.pad_leading(4, "0")
  end

  defp update(crc, <<>>), do: crc

  defp update(crc, <<c, b::binary>>) do
    update(do_update(crc, c, 0), b)
  end

  defp do_update(crc, _c, 8), do: crc

  defp do_update(crc, c, read) do
    crc = if read === 0, do: bxor(crc, c), else: crc

    if (crc &&& 0x0001) > 0 do
      do_update(bxor(crc >>> 1, @polynomial), c, read + 1)
    else
      do_update(crc >>> 1, c, read + 1)
    end
  end
end
