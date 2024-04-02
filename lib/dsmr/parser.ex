defmodule DSMR.Parser do
  @moduledoc false

  import NimbleParsec, only: [defparsecp: 3]
  import DSMR.Combinators

  alias DSMR.{MBusDevice, Telegram}

  @spec parse(binary(), keyword()) ::
          {:ok, Telegram.t()} | {:error, binary(), binary()}
  def parse(input, options) do
    tokenize_opts = [context: %{floats: Keyword.get(options, :floats, :native)}]

    case do_parse(input, tokenize_opts) do
      {:ok, tokens, "", _, _, _} ->
        [{:header, header}, {:objects, data}, {:footer, checksum}] = tokens
        telegram = %Telegram{header: header, checksum: checksum}

        {objects, channels} =
          data
          |> Enum.group_by(&group_by_mbus_channels/1)
          |> Map.pop(0, [])

        telegram =
          objects
          |> Enum.reduce(telegram, &attrs_from_object/2)
          |> Map.put(:mbus_devices, Enum.map(channels, &attrs_from_mbus_device/1))

        {:ok, telegram}

      {:error, reason, rest, _, _, _} ->
        {:error, reason, rest}
    end
  end

  @spec do_parse(binary()) ::
          {:ok, [any()], binary(), map(), {pos_integer(), pos_integer()}, pos_integer()}
          | {:error, String.t(), String.t(), map(), {non_neg_integer(), non_neg_integer()},
             non_neg_integer()}
  defparsecp(:do_parse, telegram(), inline: true)

  defp attrs_from_mbus_device({channel, objects}) do
    Enum.reduce(objects, %MBusDevice{channel: channel}, &attrs_from_object/2)
  end

  @spec attrs_from_object(Telegram.obj_t(), Telegram.t()) :: Telegram.t()
  @spec attrs_from_object(Telegram.obj_t(), MBusDevice.t()) :: MBusDevice.t()
  defp attrs_from_object({[1, 3, 0, 2, 8], value}, telegram) do
    %{telegram | version: value}
  end

  defp attrs_from_object({[0, 0, 1, 0, 0], value}, telegram) do
    %{telegram | measured_at: value}
  end

  defp attrs_from_object({[0, 0, 96, 1, 1], value}, telegram) do
    %{telegram | equipment_id: value}
  end

  defp attrs_from_object({[1, 0, 1, 8, 1], value}, telegram) do
    %{telegram | electricity_delivered_1: value}
  end

  defp attrs_from_object({[1, 0, 1, 8, 2], value}, telegram) do
    %{telegram | electricity_delivered_2: value}
  end

  defp attrs_from_object({[1, 0, 2, 8, 1], value}, telegram) do
    %{telegram | electricity_returned_1: value}
  end

  defp attrs_from_object({[1, 0, 2, 8, 2], value}, telegram) do
    %{telegram | electricity_returned_2: value}
  end

  defp attrs_from_object({[0, 0, 96, 14, 0], value}, telegram) do
    %{telegram | electricity_tariff_indicator: value}
  end

  defp attrs_from_object({[1, 0, 1, 7, 0], value}, telegram) do
    %{telegram | electricity_currently_delivered: value}
  end

  defp attrs_from_object({[1, 0, 2, 7, 0], value}, telegram) do
    %{telegram | electricity_currently_returned: value}
  end

  defp attrs_from_object({[0, 0, 96, 7, 21], value}, telegram) do
    %{telegram | power_failures_count: value}
  end

  defp attrs_from_object({[0, 0, 96, 7, 9], value}, telegram) do
    %{telegram | power_failures_long_count: value}
  end

  defp attrs_from_object({[1, 0, 99, 97, 0], value}, telegram) do
    [_count, [0, 0, 96, 7, 19] | events] = value
    events = Enum.chunk_every(events, 2)

    %{telegram | power_failures_log: events}
  end

  defp attrs_from_object({[1, 0, 32, 32, 0], value}, telegram) do
    %{telegram | voltage_sags_l1_count: value}
  end

  defp attrs_from_object({[1, 0, 52, 32, 0], value}, telegram) do
    %{telegram | voltage_sags_l2_count: value}
  end

  defp attrs_from_object({[1, 0, 72, 32, 0], value}, telegram) do
    %{telegram | voltage_sags_l3_count: value}
  end

  defp attrs_from_object({[1, 0, 32, 36, 0], value}, telegram) do
    %{telegram | voltage_swells_l1_count: value}
  end

  defp attrs_from_object({[1, 0, 52, 36, 0], value}, telegram) do
    %{telegram | voltage_swells_l2_count: value}
  end

  defp attrs_from_object({[1, 0, 72, 36, 0], value}, telegram) do
    %{telegram | voltage_swells_l3_count: value}
  end

  defp attrs_from_object({[0, 0, 96, 13, 1], value}, telegram) do
    %{telegram | text_message_codes: value}
  end

  defp attrs_from_object({[0, 0, 96, 13, 0], value}, telegram) do
    %{telegram | text_message: value}
  end

  defp attrs_from_object({[1, 0, 31, 7, 0], value}, telegram) do
    %{telegram | phase_power_current_l1: value}
  end

  defp attrs_from_object({[1, 0, 51, 7, 0], value}, telegram) do
    %{telegram | phase_power_current_l2: value}
  end

  defp attrs_from_object({[1, 0, 71, 7, 0], value}, telegram) do
    %{telegram | phase_power_current_l3: value}
  end

  defp attrs_from_object({[1, 0, 21, 7, 0], value}, telegram) do
    %{telegram | currently_delivered_l1: value}
  end

  defp attrs_from_object({[1, 0, 41, 7, 0], value}, telegram) do
    %{telegram | currently_delivered_l2: value}
  end

  defp attrs_from_object({[1, 0, 61, 7, 0], value}, telegram) do
    %{telegram | currently_delivered_l3: value}
  end

  defp attrs_from_object({[1, 0, 22, 7, 0], value}, telegram) do
    %{telegram | currently_returned_l1: value}
  end

  defp attrs_from_object({[1, 0, 42, 7, 0], value}, telegram) do
    %{telegram | currently_returned_l2: value}
  end

  defp attrs_from_object({[1, 0, 62, 7, 0], value}, telegram) do
    %{telegram | currently_returned_l3: value}
  end

  defp attrs_from_object({[0, _channel, 24, 1, 0], value}, mbus_device) do
    %{mbus_device | device_type: value}
  end

  defp attrs_from_object({[0, _channel, 96, 1, 0], value}, mbus_device) do
    %{mbus_device | equipment_id: value}
  end

  defp attrs_from_object({[0, _channel, 24, 2, 1], value}, mbus_device) do
    [measured_at, value] = value
    %{mbus_device | last_reading_measured_at: measured_at, last_reading_value: value}
  end

  # Skip any unsupported telegram objects.
  defp attrs_from_object(_object, telegram), do: telegram

  @spec group_by_mbus_channels(Telegram.obj_t()) :: non_neg_integer()
  defp group_by_mbus_channels({[0, channel, 24, 1, 0], _value}), do: channel
  defp group_by_mbus_channels({[0, channel, 96, 1, 0], _value}), do: channel
  defp group_by_mbus_channels({[0, channel, 24, 2, 1], _value}), do: channel
  defp group_by_mbus_channels(_), do: 0
end
