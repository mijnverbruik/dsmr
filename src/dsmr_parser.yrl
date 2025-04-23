Nonterminals telegram data object attributes attribute value.

Terminals header checksum float int obis string timestamp eol '*' '(' ')'.

Rootsymbol telegram.

telegram -> header eol eol data checksum eol : [extract('$1'), extract('$5'), {data, '$4'}].

data -> object eol data : ['$1' | '$3'].
data -> '$empty' : [].

object -> obis attributes : [extract('$1'), '$2'].

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
