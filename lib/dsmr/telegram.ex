defmodule DSMR.Telegram do
  defstruct header: "", checksum: "", data: []

  @type t() :: %__MODULE__{
          header: String.t(),
          checksum: String.t(),
          data: [keyword()]
        }
end
