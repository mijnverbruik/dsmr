defmodule DSMR.Timestamp do
  @enforce_keys [:value]
  defstruct [:value, dst: nil]

  @type t() :: %__MODULE__{
          value: NaiveDateTime.t(),
          dst: String.t() | nil
        }
end
