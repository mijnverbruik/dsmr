defmodule DSMR.Timestamp do
  @enforce_keys [:value, :dst]
  defstruct [:value, :dst]

  @type t() :: %__MODULE__{
          value: NaiveDateTime.t(),
          dst: String.t()
        }
end
