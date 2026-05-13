defmodule DSMR.Timestamp do
  @moduledoc """
  A DSMR timestamp.

  DSMR timestamps contain a naive date and time. Some telegrams also include a
  daylight saving time marker: `"W"` for winter time or `"S"` for summer time.
  """

  @enforce_keys [:value]
  defstruct [:value, dst: nil]

  @type t() :: %__MODULE__{
          value: NaiveDateTime.t(),
          dst: binary() | nil
        }
end
