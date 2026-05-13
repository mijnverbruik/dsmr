defmodule DSMR.MBusDevice do
  @moduledoc """
  A device connected through the meter's M-Bus interface.

  DSMR telegrams commonly use M-Bus entries for gas meters, but the same shape
  can represent water, heat, or other connected meters. Only `channel` is
  required; the remaining fields are present when the telegram includes the
  corresponding OBIS codes.
  """

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
          device_type: String.t() | nil,
          equipment_id: String.t() | nil,
          valve_position: String.t() | nil,
          last_reading_value: DSMR.Measurement.t() | nil,
          last_reading_measured_at: DSMR.Timestamp.t() | nil
        }
end
