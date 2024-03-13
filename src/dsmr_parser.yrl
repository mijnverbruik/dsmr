Nonterminals
  Telegram Objects Object
  Values Value.

Terminals
  '(' ')'
  header footer obis
  float measurement string timestamp.

Rootsymbol Telegram.

Telegram -> header Objects footer : build_node('Telegram', #{'header' => extract_value('$1'), 'data' => '$2', 'checksum' => extract_value('$3')}).

Objects -> Object Objects : ['$1' | '$2'].
Objects -> '$empty' : [].

Object -> obis Values : {extract_value('$1'), unwrap_value('$2')}.

Values -> '(' Value ')' : ['$2'].
Values -> '(' Value ')' Values : ['$2' | '$4'].
Values -> '(' ')' : nil.

Value -> float : normalize_value('$1').
Value -> obis : normalize_value('$1').
Value -> measurement : normalize_value('$1').
Value -> string : normalize_value('$1').
Value -> timestamp : normalize_value('$1').

Erlang code.

build_node(Type, Node) ->
  'Elixir.Kernel':struct(list_to_atom("Elixir.DSMR." ++ atom_to_list(Type)), Node).

extract_value({_Token, Value}) ->
  Value.

unwrap_value([Value]) ->
  Value;
unwrap_value(Value) ->
  Value.

normalize_value({'measurement' = Token, [Value, Unit]}) ->
  {Token, [normalize_value(Value), Unit]};

normalize_value({'timestamp' = Token, [Year, Month, Day, Hour, Minute, Second, DST]}) ->
  % As the year is abbreviated, we need to normalize it as well.
  DateTime = 'Elixir.NaiveDateTime':'new!'(2000 + Year, Month, Day, Hour, Minute, Second),
  {Token, [DateTime, DST]};

normalize_value({_Token, Value}) ->
  Value.
