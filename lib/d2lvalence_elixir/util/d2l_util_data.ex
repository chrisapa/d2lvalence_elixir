defmodule D2lvalenceElixir.Data do
  defmodule SupportedVersionRequest do
    @enforce_keys [:ProductCode, :Version]
    defstruct [:ProductCode, :Version]
  end
end
