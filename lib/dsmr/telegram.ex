defmodule DSMR.Telegram do
  @enforce_keys [:header, :checksum]
  defstruct [
    :header,
    :checksum,
    :version,
    :measured_at,
    :equipment_id,
    :electricity_delivered_1,
    :electricity_delivered_2,
    :electricity_returned_1,
    :electricity_returned_2,
    :electricity_tariff_indicator,
    :electricity_currently_delivered,
    :electricity_currently_returned,
    :power_failures_count,
    :power_failures_long_count,
    :power_failures_log,
    :voltage_sags_l1_count,
    :voltage_sags_l2_count,
    :voltage_sags_l3_count,
    :voltage_swells_l1_count,
    :voltage_swells_l2_count,
    :voltage_swells_l3_count,
    :actual_threshold_electricity,
    :actual_switch_position,
    :text_message,
    :text_message_code,
    :phase_power_current_l1,
    :phase_power_current_l2,
    :phase_power_current_l3,
    :currently_delivered_l1,
    :currently_delivered_l2,
    :currently_delivered_l3,
    :currently_returned_l1,
    :currently_returned_l2,
    :currently_returned_l3,
    mbus_devices: []
  ]

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
          version: String.t(),
          measured_at: DSMR.Timestamp.t(),
          equipment_id: String.t(),
          electricity_delivered_1: DSMR.Measurement.t(),
          electricity_delivered_2: DSMR.Measurement.t(),
          electricity_returned_1: DSMR.Measurement.t(),
          electricity_returned_2: DSMR.Measurement.t(),
          electricity_tariff_indicator: String.t(),
          electricity_currently_delivered: DSMR.Measurement.t(),
          electricity_currently_returned: DSMR.Measurement.t(),
          power_failures_count: String.t(),
          power_failures_long_count: String.t(),
          power_failures_log: [{DSMR.Timestamp.t(), DSMR.Measurement.t()}],
          voltage_sags_l1_count: String.t(),
          voltage_sags_l2_count: String.t(),
          voltage_sags_l3_count: String.t(),
          voltage_swells_l1_count: String.t(),
          voltage_swells_l2_count: String.t(),
          voltage_swells_l3_count: String.t(),
          actual_threshold_electricity: DSMR.Measurement.t(),
          actual_switch_position: String.t(),
          text_message: String.t(),
          text_message_code: String.t(),
          phase_power_current_l1: DSMR.Measurement.t(),
          phase_power_current_l2: DSMR.Measurement.t(),
          phase_power_current_l3: DSMR.Measurement.t(),
          currently_delivered_l1: DSMR.Measurement.t(),
          currently_delivered_l2: DSMR.Measurement.t(),
          currently_delivered_l3: DSMR.Measurement.t(),
          currently_returned_l1: DSMR.Measurement.t(),
          currently_returned_l2: DSMR.Measurement.t(),
          currently_returned_l3: DSMR.Measurement.t(),
          mbus_devices: [DSMR.MBusDevice.t()]
        }
end
