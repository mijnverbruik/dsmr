defmodule DSMR.Measurement do
  @enforce_keys [:value, :unit]
  defstruct [:value, :unit]

  @type t() :: %__MODULE__{
          value: float() | Decimal.t(),
          unit: String.t()
        }
end
