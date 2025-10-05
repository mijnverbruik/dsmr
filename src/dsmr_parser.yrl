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

extract({T, _, V}) ->
  {T, V}.

%% Map OBIS codes to telegram field names
%% Uses DSMR.OBIS Elixir module as single source of truth for standard mappings.
%% Special cases (MBus devices, power failures log) are handled here due to wildcards.

%% Special case: power failures log (needs special processing in parser)
map_obis_to_field({obis, _, {[1,0,99,97,0], _}}, Attrs) ->
  {telegram_field, power_failures_log, Attrs};

%% MBus device fields - these patterns use wildcards so can't be in the map
map_obis_to_field({obis, _, {[0,_,24,1,0], Channel}}, Attrs) ->
  {mbus_field, Channel, device_type, Attrs};
map_obis_to_field({obis, _, {[0,_,96,1,0], Channel}}, Attrs) ->
  {mbus_field, Channel, equipment_id, Attrs};
map_obis_to_field({obis, _, {[0,_,24,2,1], Channel}}, Attrs) ->
  {mbus_field, Channel, last_reading, Attrs};
map_obis_to_field({obis, _, {[0,_,24,4,0], Channel}}, Attrs) ->
  {mbus_field, Channel, valve_position, Attrs};
map_obis_to_field({obis, _, {[0,_,24,3,0], Channel}}, Attrs) ->
  {mbus_field, Channel, legacy_gas_reading, Attrs};

%% Standard telegram fields - delegate to Elixir OBIS module
map_obis_to_field({obis, _, {Code, _}}, Attrs) ->
  case 'Elixir.DSMR.OBIS':get_field(Code) of
    nil -> {unknown_obis, Code, Attrs};
    Field -> {telegram_field, Field, Attrs}
  end.
