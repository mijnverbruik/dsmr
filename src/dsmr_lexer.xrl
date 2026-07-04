Definitions.

% Whitespace
CRLF = \r\n

% Characters
D     = [0-9]
INT   = [0-9]+
ALNUM = [0-9a-zA-Z]+
FLOAT = {INT}\.{INT}

OBIS      = {INT}\-{INT}\:{INT}\.{INT}\.{INT}
% At least 12 digits (YYMMDDhhmmss) followed by a DST marker. leex has no
% bounded repetition, so the exact length is validated in the rule action.
TIMESTAMP = {D}{D}{D}{D}{D}{D}{D}{D}{D}{D}{D}{D}{INT}?[WS]

HEADER = \/[^{CRLF}]+
FOOTER = \![^{CRLF}]*

Rules.

{HEADER}    : {token, {header, TokenLine, without_prefix(TokenChars, TokenLen)}}.
{FOOTER}    : {token, {checksum, TokenLine, without_prefix(TokenChars, TokenLen)}}.
{OBIS}      : {token, {obis, TokenLine, to_obis(TokenChars)}}.
{TIMESTAMP} : to_timestamp(TokenChars, TokenLine, TokenLen).
{FLOAT}     : {token, {float, TokenLine, list_to_binary(TokenChars)}}.
{INT}       : {token, {int, TokenLine, list_to_binary(TokenChars)}}.
{ALNUM}     : {token, {string, TokenLine, list_to_binary(TokenChars)}}.
[()\*]      : {token, {list_to_atom(TokenChars), TokenLine}}.
{CRLF}\(    : {skip_token, [$(]}.
{CRLF}      : {token, {eol, TokenLine}}.

Erlang code.

to_obis(TokenChars) ->
  Tokens = string:tokens(TokenChars, "-:."),
  [A, B, C, D, E] = lists:map(fun list_to_integer/1, Tokens),
  %% Extract channel from second position (for MBus devices)
  {[A, B, C, D, E], B}.

%% A timestamp is exactly 12 digits (YYMMDDhhmmss) plus a DST marker; the
%% rule matches longer digit runs so they can be rejected with a clean error.
to_timestamp([Y1,Y2,Mo1,Mo2,D1,D2,H1,H2,Mi1,Mi2,S1,S2,DSTChar], TokenLine, 13) ->
  Pairs = [[Y1,Y2], [Mo1,Mo2], [D1,D2], [H1,H2], [Mi1,Mi2], [S1,S2]],
  IntValues = lists:map(fun list_to_integer/1, Pairs),
  {token, {timestamp, TokenLine, {IntValues, <<DSTChar>>}}};
to_timestamp(_TokenChars, _TokenLine, TokenLen) ->
  {error, "timestamp must be 12 digits followed by W or S, got "
          ++ integer_to_list(TokenLen - 1) ++ " digits"}.

without_prefix(TokenChars, TokenLen) ->
  Chars = lists:sublist(TokenChars, 2, TokenLen - 1),
  list_to_binary(Chars).
