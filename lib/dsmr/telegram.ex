defmodule DSMR.Telegram do
  @moduledoc false
  defstruct header: nil, checksum: nil, data: []

  defmodule Value do
    @moduledoc false
    defstruct value: nil, unit: nil

    def new({:value, [{_type, value}, unit: unit]}) do
      %Value{value: value, unit: unit}
    end

    def new({:value, [{_type, value}]}) do
      %Value{value: value}
    end
  end

  defmodule OBIS do
    @moduledoc false
    defstruct code: nil

    def new({:obis, code}) do
      %OBIS{code: code}
    end
  end

  defmodule COSEM do
    @moduledoc false
    defstruct obis: nil, values: []

    def new([obis | values]) do
      obis = OBIS.new(obis)
      values = Enum.map(values, &Value.new/1)

      %COSEM{obis: obis, values: values}
    end
  end

  defmodule Header do
    @moduledoc false
    defstruct manufacturer: nil, model: nil

    def new([{:manufacturer, manufacturer}, {:model, model}]) do
      %Header{manufacturer: manufacturer, model: model}
    end
  end

  defmodule Checksum do
    @moduledoc false
    defstruct value: nil

    def new(checksum) do
      %Checksum{value: checksum}
    end
  end
end
