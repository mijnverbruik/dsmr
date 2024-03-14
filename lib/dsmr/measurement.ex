defmodule DSMR.Measurement do
  defstruct value: nil, unit: ""

  @type t() :: %__MODULE__{
          value: float() | Decimal.t(),
          unit: String.t()
        }
end
