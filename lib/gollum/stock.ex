defmodule Gollum.Stock do
  @enforce_keys [:symbol, :price, :amount, :value]
  defstruct [:symbol, :price, :amount, :value]

  @type symbol :: String.t()
  @type shares :: {integer(), String.t()}

  @type t :: %__MODULE__{
          symbol: String.t(),
          price: Decimal.t(),
          amount: integer(),
          value: Decimal.t()
        }

  alias __MODULE__.Snapshot

  require Logger

  def new(symbol) when is_binary(symbol) do
    %__MODULE__{symbol: symbol, price: Decimal.new(0), amount: 0, value: Decimal.new(0)}
  end

  @spec buy(symbol, shares()) :: {:ok, t()}
  def buy(symbol, shares) when is_binary(symbol) do
    symbol
    |> new()
    |> buy(shares)
  end

  @spec buy(__MODULE__.t(), shares()) :: {:ok, __MODULE__.t()}
  def buy(%__MODULE__{} = former, shares) do
    with {:ok, shares} = to_shares(shares),
         {:ok, current} <- do_buy(former, shares),
         :ok <- save_snapshot(:buy, former, current) do
      {:ok, current}
    end
  end

  defp do_buy(pos, shares) do
    value = to_value(shares)

    new_amount = pos.amount + shares.amount

    new_price =
      pos.value
      |> Decimal.add(value)
      |> Decimal.div(new_amount)

    new_value = to_value(new_price, new_amount)

    {:ok, %__MODULE__{pos | price: new_price, amount: new_amount, value: new_value}}
  end

  @spec sell(__MODULE__.t(), shares()) :: {:ok, __MODULE__.t()}
  def sell(%__MODULE__{} = former, shares) do
    with {:ok, shares} <- to_shares(shares),
         {:ok, current} <- do_sell(former, shares),
         :ok <- save_snapshot(:sell, former, current) do
      {:ok, current}
    end
  end

  defp do_sell(pos, shares) do
    cond do
      pos.amount == shares.amount ->
        {:ok, new(pos.symbol)}

      pos.amount < shares.amount ->
        {:error, :insufficient_shares}

      true ->
        new_amount = pos.amount - shares.amount
        new_value = to_value(pos.price, new_amount)

        {:ok, %__MODULE__{pos | price: pos.price, amount: new_amount, value: new_value}}
    end
  end

  defp to_shares({amount, price} = shares)
       when is_integer(elem(shares, 0)) and is_binary(elem(shares, 1)) do
    with {price, ""} <- Decimal.parse(price),
         true <- amount > 0 do
      {:ok, %{amount: amount, price: price}}
    else
      {_, _} -> {:error, :invalid_price}
      :error -> {:error, :invalid_price}
      false -> {:error, :invalid_amount}
    end
  end

  defp to_value(shares), do: to_value(shares.price, shares.amount)

  defp to_value(price, amount) when is_integer(amount) and is_struct(price, Decimal),
    do: Decimal.mult(price, amount)

  defp save_snapshot(action, _former, current) do
    snapshot =
      %Snapshot{
        symbol: current.symbol,
        price: current.price,
        amount: current.amount,
        value: current.value,
        action_type: action
      }

    Logger.info("Saved snapshot: #{inspect(snapshot)}")

    :ok
  end
end
