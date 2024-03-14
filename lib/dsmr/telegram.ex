defmodule DSMR.Telegram do
  defstruct header: "", checksum: "", data: []

  @type obis_t() ::
          {non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer(),
           non_neg_integer()}

  @type value_t() ::
          String.t()
          | obis_t()
          | DSMR.Timestamp.t()
          | DSMR.Measurement.t()

  @type obj_t() :: {obis_t(), value_t() | [value_t()]}

  @type t() :: %__MODULE__{
          header: String.t(),
          checksum: String.t(),
          data: [obj_t()]
        }
end
