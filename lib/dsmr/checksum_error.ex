defmodule DSMR.ChecksumError do
  @type t :: %__MODULE__{checksum: binary()}

  defexception [:checksum]

  @impl true
  def message(_exception), do: "checksum mismatch"
end
