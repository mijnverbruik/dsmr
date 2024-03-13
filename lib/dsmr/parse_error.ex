defmodule DSMR.ParseError do
  @type t :: %__MODULE__{message: binary()}

  defexception [:message]
end
