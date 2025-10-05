Nonterminals telegram data object attributes attribute value.

Terminals header checksum float int obis string timestamp eol '*' '(' ')'.

Rootsymbol telegram.

telegram -> header eol eol data checksum eol : [extract('$1'), extract('$5'), {data, '$4'}].

data -> object eol data : ['$1' | '$3'].
data -> '$empty' : [].

object -> obis attributes : map_obis_to_field('$1', '$2').

attributes -> attribute attributes : ['$1' | '$2'].
attributes -> attribute : ['$1'].

attribute -> '(' value ')' : '$2'.
attribute -> '(' ')' : nil.

value -> float '*' string : extract_measurement('$1', '$3').
value -> int '*' string : extract_measurement('$1', '$3').

value -> float : extract_string('$1').
value -> int : extract_string('$1').
value -> obis : extract('$1').
value -> string : extract('$1').
value -> timestamp : extract('$1').

Erlang code.

extract_measurement(V, {_,_,U}) ->
  {measurement, {extract(V), U}}.

extract_string({_,_,V}) ->
  {string, V}.

extract({T,_,V}) ->
  {T, V}.

%% Map OBIS codes to telegram field names
map_obis_to_field({obis, _, [1,3,0,2,8]}, Attrs) -> {telegram_field, version, Attrs};
map_obis_to_field({obis, _, [0,0,1,0,0]}, Attrs) -> {telegram_field, measured_at, Attrs};
map_obis_to_field({obis, _, [0,0,96,1,1]}, Attrs) -> {telegram_field, equipment_id, Attrs};
map_obis_to_field({obis, _, [1,0,1,8,1]}, Attrs) -> {telegram_field, electricity_delivered_1, Attrs};
map_obis_to_field({obis, _, [1,0,1,8,2]}, Attrs) -> {telegram_field, electricity_delivered_2, Attrs};
map_obis_to_field({obis, _, [1,0,2,8,1]}, Attrs) -> {telegram_field, electricity_returned_1, Attrs};
map_obis_to_field({obis, _, [1,0,2,8,2]}, Attrs) -> {telegram_field, electricity_returned_2, Attrs};
map_obis_to_field({obis, _, [0,0,96,14,0]}, Attrs) -> {telegram_field, electricity_tariff_indicator, Attrs};
map_obis_to_field({obis, _, [1,0,1,7,0]}, Attrs) -> {telegram_field, electricity_currently_delivered, Attrs};
map_obis_to_field({obis, _, [1,0,2,7,0]}, Attrs) -> {telegram_field, electricity_currently_returned, Attrs};
map_obis_to_field({obis, _, [0,0,96,7,21]}, Attrs) -> {telegram_field, power_failures_count, Attrs};
map_obis_to_field({obis, _, [0,0,96,7,9]}, Attrs) -> {telegram_field, power_failures_long_count, Attrs};
map_obis_to_field({obis, _, [1,0,32,32,0]}, Attrs) -> {telegram_field, voltage_sags_l1_count, Attrs};
map_obis_to_field({obis, _, [1,0,52,32,0]}, Attrs) -> {telegram_field, voltage_sags_l2_count, Attrs};
map_obis_to_field({obis, _, [1,0,72,32,0]}, Attrs) -> {telegram_field, voltage_sags_l3_count, Attrs};
map_obis_to_field({obis, _, [1,0,32,36,0]}, Attrs) -> {telegram_field, voltage_swells_l1_count, Attrs};
map_obis_to_field({obis, _, [1,0,52,36,0]}, Attrs) -> {telegram_field, voltage_swells_l2_count, Attrs};
map_obis_to_field({obis, _, [1,0,72,36,0]}, Attrs) -> {telegram_field, voltage_swells_l3_count, Attrs};
map_obis_to_field({obis, _, [0,0,17,0,0]}, Attrs) -> {telegram_field, actual_threshold_electricity, Attrs};
map_obis_to_field({obis, _, [0,0,96,3,10]}, Attrs) -> {telegram_field, actual_switch_position, Attrs};
map_obis_to_field({obis, _, [0,0,96,13,0]}, Attrs) -> {telegram_field, text_message, Attrs};
map_obis_to_field({obis, _, [0,0,96,13,1]}, Attrs) -> {telegram_field, text_message_code, Attrs};
map_obis_to_field({obis, _, [1,0,31,7,0]}, Attrs) -> {telegram_field, phase_power_current_l1, Attrs};
map_obis_to_field({obis, _, [1,0,51,7,0]}, Attrs) -> {telegram_field, phase_power_current_l2, Attrs};
map_obis_to_field({obis, _, [1,0,71,7,0]}, Attrs) -> {telegram_field, phase_power_current_l3, Attrs};
map_obis_to_field({obis, _, [1,0,21,7,0]}, Attrs) -> {telegram_field, currently_delivered_l1, Attrs};
map_obis_to_field({obis, _, [1,0,41,7,0]}, Attrs) -> {telegram_field, currently_delivered_l2, Attrs};
map_obis_to_field({obis, _, [1,0,61,7,0]}, Attrs) -> {telegram_field, currently_delivered_l3, Attrs};
map_obis_to_field({obis, _, [1,0,22,7,0]}, Attrs) -> {telegram_field, currently_returned_l1, Attrs};
map_obis_to_field({obis, _, [1,0,42,7,0]}, Attrs) -> {telegram_field, currently_returned_l2, Attrs};
map_obis_to_field({obis, _, [1,0,62,7,0]}, Attrs) -> {telegram_field, currently_returned_l3, Attrs};

%% Special cases and MBus devices
map_obis_to_field({obis, _, [1,0,99,97,0]}, Attrs) -> {telegram_field, power_failures_log, Attrs};
map_obis_to_field({obis, _, [0,Channel,24,1,0]}, Attrs) -> {mbus_field, Channel, device_type, Attrs};
map_obis_to_field({obis, _, [0,Channel,96,1,0]}, Attrs) -> {mbus_field, Channel, equipment_id, Attrs};
map_obis_to_field({obis, _, [0,Channel,24,2,1]}, Attrs) -> {mbus_field, Channel, last_reading, Attrs};
map_obis_to_field({obis, _, [0,1,24,4,0]}, Attrs) -> {mbus_field, 1, valve_position, Attrs};
map_obis_to_field({obis, _, [0,1,24,3,0]}, Attrs) -> {mbus_field, 1, legacy_gas_reading, Attrs};

%% Voltage fields (DSMR 5.0+)
map_obis_to_field({obis, _, [1,0,32,7,0]}, Attrs) -> {telegram_field, voltage_l1, Attrs};
map_obis_to_field({obis, _, [1,0,52,7,0]}, Attrs) -> {telegram_field, voltage_l2, Attrs};
map_obis_to_field({obis, _, [1,0,72,7,0]}, Attrs) -> {telegram_field, voltage_l3, Attrs};

%% Unknown OBIS code - preserve raw structure
map_obis_to_field({obis, _, Code}, Attrs) -> {unknown_obis, Code, Attrs}.
