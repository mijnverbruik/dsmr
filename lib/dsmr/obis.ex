defmodule DSMR.OBIS do
  @moduledoc """
  Centralized OBIS code mapping for DSMR telegrams.

  This module is the single source of truth for OBIS code mappings.
  The parser (src/dsmr_parser.yrl) calls this module directly at runtime.
  """

  # Define mappings as ordered keyword list: field => OBIS string
  # Order matters - this defines the serialization order for telegrams
  @telegram_field_mappings [
    version: "1-3:0.2.8",
    measured_at: "0-0:1.0.0",
    equipment_id: "0-0:96.1.1",
    electricity_delivered_1: "1-0:1.8.1",
    electricity_delivered_2: "1-0:1.8.2",
    electricity_returned_1: "1-0:2.8.1",
    electricity_returned_2: "1-0:2.8.2",
    electricity_tariff_indicator: "0-0:96.14.0",
    electricity_currently_delivered: "1-0:1.7.0",
    electricity_currently_returned: "1-0:2.7.0",
    power_failures_count: "0-0:96.7.21",
    power_failures_long_count: "0-0:96.7.9",
    power_failures_log: nil,
    voltage_sags_l1_count: "1-0:32.32.0",
    voltage_sags_l2_count: "1-0:52.32.0",
    voltage_sags_l3_count: "1-0:72.32.0",
    voltage_swells_l1_count: "1-0:32.36.0",
    voltage_swells_l2_count: "1-0:52.36.0",
    voltage_swells_l3_count: "1-0:72.36.0",
    actual_threshold_electricity: "0-0:17.0.0",
    actual_switch_position: "0-0:96.3.10",
    text_message_code: "0-0:96.13.1",
    text_message: "0-0:96.13.0",
    voltage_l1: "1-0:32.7.0",
    voltage_l2: "1-0:52.7.0",
    voltage_l3: "1-0:72.7.0",
    phase_power_current_l1: "1-0:31.7.0",
    phase_power_current_l2: "1-0:51.7.0",
    phase_power_current_l3: "1-0:71.7.0",
    currently_delivered_l1: "1-0:21.7.0",
    currently_delivered_l2: "1-0:41.7.0",
    currently_delivered_l3: "1-0:61.7.0",
    currently_returned_l1: "1-0:22.7.0",
    currently_returned_l2: "1-0:42.7.0",
    currently_returned_l3: "1-0:62.7.0"
  ]

  # Build reverse mapping at compile time: OBIS list => field name
  @obis_to_field_mappings @telegram_field_mappings
                          |> Enum.reject(fn {_field, obis_str} -> is_nil(obis_str) end)
                          |> Enum.map(fn {field, obis_str} ->
                            # Convert "1-3:0.2.8" to [1,3,0,2,8]
                            obis_list =
                              obis_str
                              |> String.replace(["-", ":"], ".")
                              |> String.split(".")
                              |> Enum.map(&String.to_integer/1)

                            {obis_list, field}
                          end)
                          |> Map.new()

  @doc """
  Returns the OBIS code string for a given telegram field.

  Used by serialization logic (Telegram.to_string/1).

  ## Examples

      iex> DSMR.OBIS.get_obis(:version)
      "1-3:0.2.8"

      iex> DSMR.OBIS.get_obis(:electricity_delivered_1)
      "1-0:1.8.1"
  """
  @spec get_obis(atom()) :: String.t() | nil
  def get_obis(field) do
    Keyword.get(@telegram_field_mappings, field)
  end

  @doc """
  Returns the ordered list of telegram fields for serialization.

  The order matches the DSMR specification and is used when converting
  a Telegram struct to its string representation.

  ## Examples

      iex> fields = DSMR.OBIS.field_order()
      iex> hd(fields)
      :version
      iex> :electricity_delivered_1 in fields
      true
  """
  @spec field_order() :: [atom()]
  def field_order do
    Keyword.keys(@telegram_field_mappings)
  end

  @doc """
  Returns the field name for a given OBIS code list.

  Used by the parser to map OBIS codes to struct fields.
  This function is called from Erlang code in dsmr_parser.yrl.

  ## Examples

      iex> DSMR.OBIS.get_field([1, 3, 0, 2, 8])
      :version

      iex> DSMR.OBIS.get_field([1, 0, 1, 8, 1])
      :electricity_delivered_1

      iex> DSMR.OBIS.get_field([99, 99, 99, 99, 99])
      nil
  """
  @spec get_field(list(non_neg_integer())) :: atom() | nil
  def get_field(obis_list) when is_list(obis_list) do
    Map.get(@obis_to_field_mappings, obis_list)
  end

  @doc """
  Returns all field-to-OBIS mappings as a map.
  """
  @spec all_mappings() :: %{atom() => String.t()}
  def all_mappings do
    @telegram_field_mappings
    |> Enum.reject(fn {_field, obis_str} -> is_nil(obis_str) end)
    |> Map.new()
  end
end
