defmodule DSMR.Timestamp do
  defstruct value: nil, dst: ""

  @type t() :: %__MODULE__{
          value: NaiveDateTime.t(),
          dst: String.t()
        }
end
