defmodule DSMR.Measurement do
  @moduledoc """
  A numeric value with a DSMR unit.

  Measurements are used for electricity, gas, voltage, current, and duration
  values. Values are parsed as native numbers by default. When `DSMR.parse/2`
  is called with `floats: :decimals`, decimal values are returned as
  `%Decimal{}` structs.
  """

  @enforce_keys [:value, :unit]
  defstruct [:value, :unit, raw: nil]

  @typedoc """
  `raw` holds the exact numeric text from the telegram (e.g. `"000123.456"`)
  so that serialization can reproduce the original padding and precision.
  It is `nil` for measurements constructed by hand.
  """
  @type t() :: %__MODULE__{
          value: integer() | float() | Decimal.t(),
          unit: String.t(),
          raw: String.t() | nil
        }
end
