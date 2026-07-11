defmodule DSMR.OBIS do
  @moduledoc """
  OBIS code mappings used by the parser and serializer.

  OBIS codes identify the values contained in a DSMR telegram. This module maps
  known codes to `%DSMR.Telegram{}` fields and exposes the reverse mapping used
  by `DSMR.Telegram.to_string/1`.
  """

  # Single source of truth for telegram fields: field => {OBIS string, value type}.
  # Order matters - this defines the serialization order for telegrams.
  # The value type drives the generated `DSMR.Telegram` struct typespec.
  #
  # Measurement fields carry the spec-defined value format as
  # `{:measurement, {integer_digits, decimals}}` (e.g. F9(3,3) => `{6, 3}`),
  # used when serializing hand-built measurements that have no `raw` value.
  @telegram_field_definitions [
    version: {"1-3:0.2.8", :string},
    measured_at: {"0-0:1.0.0", :timestamp},
    equipment_id: {"0-0:96.1.1", :string},
    electricity_delivered_1: {"1-0:1.8.1", {:measurement, {6, 3}}},
    electricity_delivered_2: {"1-0:1.8.2", {:measurement, {6, 3}}},
    electricity_returned_1: {"1-0:2.8.1", {:measurement, {6, 3}}},
    electricity_returned_2: {"1-0:2.8.2", {:measurement, {6, 3}}},
    electricity_tariff_indicator: {"0-0:96.14.0", :string},
    electricity_currently_delivered: {"1-0:1.7.0", {:measurement, {2, 3}}},
    electricity_currently_returned: {"1-0:2.7.0", {:measurement, {2, 3}}},
    power_failures_count: {"0-0:96.7.21", :string},
    power_failures_long_count: {"0-0:96.7.9", :string},
    power_failures_log: {nil, :power_failures_log},
    voltage_sags_l1_count: {"1-0:32.32.0", :string},
    voltage_sags_l2_count: {"1-0:52.32.0", :string},
    voltage_sags_l3_count: {"1-0:72.32.0", :string},
    voltage_swells_l1_count: {"1-0:32.36.0", :string},
    voltage_swells_l2_count: {"1-0:52.36.0", :string},
    voltage_swells_l3_count: {"1-0:72.36.0", :string},
    actual_threshold_electricity: {"0-0:17.0.0", {:measurement, {3, 1}}},
    actual_switch_position: {"0-0:96.3.10", :string},
    text_message_code: {"0-0:96.13.1", :string},
    text_message: {"0-0:96.13.0", :string},
    # Voltage is padded to 4 integer digits, matching the example telegrams
    # in the DSMR 5.0.2 P1 companion standard ("0230.0*V").
    voltage_l1: {"1-0:32.7.0", {:measurement, {4, 1}}},
    voltage_l2: {"1-0:52.7.0", {:measurement, {4, 1}}},
    voltage_l3: {"1-0:72.7.0", {:measurement, {4, 1}}},
    phase_power_current_l1: {"1-0:31.7.0", {:measurement, {3, 0}}},
    phase_power_current_l2: {"1-0:51.7.0", {:measurement, {3, 0}}},
    phase_power_current_l3: {"1-0:71.7.0", {:measurement, {3, 0}}},
    currently_delivered_l1: {"1-0:21.7.0", {:measurement, {2, 3}}},
    currently_delivered_l2: {"1-0:41.7.0", {:measurement, {2, 3}}},
    currently_delivered_l3: {"1-0:61.7.0", {:measurement, {2, 3}}},
    currently_returned_l1: {"1-0:22.7.0", {:measurement, {2, 3}}},
    currently_returned_l2: {"1-0:42.7.0", {:measurement, {2, 3}}},
    currently_returned_l3: {"1-0:62.7.0", {:measurement, {2, 3}}}
  ]

  @telegram_field_mappings Enum.map(@telegram_field_definitions, fn {field, {obis, _type}} ->
                             {field, obis}
                           end)

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
  for {field, obis_str} <- @telegram_field_mappings do
    def get_obis(unquote(field)), do: unquote(obis_str)
  end

  def get_obis(_field), do: nil

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
  Returns the ordered field definitions: `{field, {obis_string, value_type}}`.

  This is the single source of truth for telegram fields; `DSMR.Telegram`
  derives its struct and typespec from it at compile time.
  """
  @spec field_definitions() :: [
          {atom(),
           {String.t() | nil,
            :string | :timestamp | {:measurement, format()} | :power_failures_log}}
        ]
  def field_definitions, do: @telegram_field_definitions

  @typedoc """
  Spec-defined measurement value format as `{integer_digits, decimals}`.

  For example the DSMR `F9(3,3)` energy register format is `{6, 3}`:
  six integer digits and three decimals.
  """
  @type format() :: {non_neg_integer(), non_neg_integer()}

  @measurement_formats Enum.flat_map(@telegram_field_definitions, fn
                         {field, {_obis, {:measurement, format}}} -> [{field, format}]
                         _ -> []
                       end)
                       |> Map.new()

  @doc """
  Returns the spec-defined measurement format for a field, or `nil` when the
  field is not a measurement.

  ## Examples

      iex> DSMR.OBIS.get_format(:voltage_l1)
      {3, 1}

      iex> DSMR.OBIS.get_format(:version)
      nil
  """
  @spec get_format(atom()) :: format() | nil
  def get_format(field), do: Map.get(@measurement_formats, field)

  @doc """
  Returns all field-to-OBIS mappings as a map.
  """
  @all_mappings @telegram_field_mappings
                |> Enum.reject(fn {_field, obis_str} -> is_nil(obis_str) end)
                |> Map.new()

  @spec all_mappings() :: %{atom() => String.t()}
  def all_mappings, do: @all_mappings
end
