defmodule DSMR.Telegram do
  defstruct header: "", checksum: "", data: []

  @type obis_t() ::
          {non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer(),
           non_neg_integer()}

  @type value_t() ::
          binary()
          | obis_t()
          | {:timestamp, NaiveDateTime.t(), binary()}
          | {:measurement, float() | Decimal.t(), binary()}

  @type obj_t() :: {obis_t(), value_t() | [value_t()]}

  @type t() :: %__MODULE__{
          header: String.t(),
          checksum: String.t(),
          data: [obj_t()]
        }
end
