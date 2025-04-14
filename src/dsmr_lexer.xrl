Definitions.

% Whitespace
CRLF = \r\n

% Characters
INT   = [0-9]+
ALNUM = [0-9a-zA-Z]+
FLOAT = {INT}\.{INT}

OBIS      = {INT}\-{INT}\:{INT}\.{INT}\.{INT}
TIMESTAMP = {INT}{INT}{INT}{INT}{INT}{INT}{INT}{INT}{INT}{INT}{INT}{INT}[WS]

HEADER = \/[^{CRLF}]+
FOOTER = \![^{CRLF}]*

Rules.

{HEADER}    : {token, {header, TokenLine, without_prefix(TokenChars, TokenLen)}}.
{FOOTER}    : {token, {checksum, TokenLine, without_prefix(TokenChars, TokenLen)}}.
{OBIS}      : {token, {obis, TokenLine, to_obis(TokenChars)}}.
{TIMESTAMP} : {token, {timestamp, TokenLine, to_timestamp(TokenChars, TokenLen)}}.
{FLOAT}     : {token, {float, TokenLine, list_to_binary(TokenChars)}}.
{INT}       : {token, {int, TokenLine, list_to_binary(TokenChars)}}.
{ALNUM}     : {token, {string, TokenLine, list_to_binary(TokenChars)}}.
[()\*]      : {token, {list_to_atom(TokenChars), TokenLine}}.
{CRLF}\(    : {skip_token, [$(]}.
{CRLF}      : {token, {eol, TokenLine}}.

Erlang code.

to_obis(TokenChars) -> 
  Tokens = string:tokens(TokenChars, "-:."),
  lists:map(fun list_to_integer/1, Tokens).

to_timestamp(TokenChars, TokenLen) ->
  TimestampChars = lists:sublist(TokenChars, 1, TokenLen - 1),
  DSTChar = lists:last(TokenChars),

  Indices = lists:seq(1, TokenLen - 1, 2),
  Pairs = [lists:sublist(TimestampChars, I, 2) || I <- Indices],

  IntValues = lists:map(fun list_to_integer/1, Pairs),
  {IntValues, <<DSTChar>>}.

without_prefix(TokenChars, TokenLen) ->
  Chars = lists:sublist(TokenChars, 2, TokenLen - 1),
  list_to_binary(Chars).
