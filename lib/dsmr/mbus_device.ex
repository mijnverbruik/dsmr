defmodule DSMR.MBusDevice do
  @enforce_keys [:channel]
  defstruct [
    :channel,
    :device_type,
    :equipment_id,
    :valve_position,
    :last_reading_value,
    :last_reading_measured_at
  ]

  @type t() :: %__MODULE__{
          channel: non_neg_integer(),
          device_type: String.t(),
          equipment_id: String.t(),
          valve_position: String.t(),
          last_reading_value: DSMR.Measurement.t(),
          last_reading_measured_at: DSMR.Timestamp.t()
        }
end
