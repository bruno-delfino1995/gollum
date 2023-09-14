defmodule Gollum.StockTest do
  use ExUnit.Case, async: true

  alias Gollum.Stock

  describe "buy/2" do
    test "transforms a symbol purchase into a stock" do
      symbol = "ABC"
      price = "10"
      amount = 23

      {:ok, pos} = Stock.buy(symbol, {amount, price})

      assert pos.symbol == symbol
      assert Decimal.eq?(pos.price, price)
      assert pos.amount == amount
      assert pos.value == Decimal.mult(price, amount)
    end

    test "blatantly increases the amount" do
      amount = 17
      shares = {amount, "1"}

      {:ok, initial} = Stock.buy("ABC", shares)
      {:ok, final} = Stock.buy(initial, shares)

      assert final.amount == amount * 2
    end

    test "maintains price when buying at the current" do
      shares = {3, "7"}

      {:ok, initial} = Stock.buy("ABC", shares)
      {:ok, final} = Stock.buy(initial, shares)

      assert Decimal.eq?(final.price, "7")
    end

    test "decreases price when buying below current" do
      {:ok, initial} = Stock.buy("ABC", {5, "11"})
      {:ok, final} = Stock.buy(initial, {13, "3"})

      assert Decimal.gt?(initial.price, final.price)
    end

    test "increases price when buying above current" do
      {:ok, initial} = Stock.buy("ABC", {17, "11"})
      {:ok, final} = Stock.buy(initial, {31, "29"})

      assert Decimal.lt?(initial.price, final.price)
    end
  end

  describe "sell/2" do
    test "blatantly decreases the amount" do
      {:ok, initial} = Stock.buy("ABC", {17, "1"})
      {:ok, final} = Stock.sell(initial, {6, "3"})

      assert final.amount == 11
    end

    test "you can't sell more than you have" do
      {:ok, initial} = Stock.buy("ABC", {17, "1"})

      assert {:ok, _} = Stock.sell(initial, {16, "3"})
      assert {:error, :insufficient_shares} = Stock.sell(initial, {18, "3"})
    end

    test "resets to bare if you sell everything" do
      {:ok, initial} = Stock.buy("ABC", {31, "1"})
      {:ok, final} = Stock.sell(initial, {31, "3"})

      assert final.symbol == "ABC"
      assert final.amount == 0
      assert Decimal.eq?(final.price, 0)
      assert Decimal.eq?(final.value, 0)
    end

    test "always maintains the price when selling" do
      {:ok, initial} = Stock.buy("ABC", {17, "1"})
      {:ok, final} = Stock.sell(initial, {6, "3"})

      assert Decimal.eq?(final.price, 1)
    end
  end
end
