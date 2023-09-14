defmodule Gollum.Stock.Snapshot do
  @enforce_keys [:symbol, :price, :amount, :value, :action_type]
  defstruct [:symbol, :price, :amount, :value, :action_type, :action_details, :action_results]

  @type t :: %__MODULE__{
          symbol: String.t(),
          price: Decimal.t(),
          amount: non_neg_integer(),
          value: Decimal.t(),
          action_type: atom(),
          action_details: map(),
          action_results: map()
        }
end
