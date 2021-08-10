defmodule Blackjack do
  # Development Commands

  ###### END ######

  # Utilities

  def via_tuple(registry, name) do
    {:via, Registry, {registry, name}}
  end

  def format_name(name) do
    name
    |> String.trim()
    |> String.replace(" ", "_")
    |> String.to_atom()
  end

  def unformat_name(name) do
    name
    |> String.trim()
    |> String.replace("_", " ")
  end

  def lookup(registry, name) do
    [{pid, _}] = Registry.lookup(registry, name)
    pid
  end

  def name(registry, pid) do
    Registry.keys(registry, pid) |> Enum.at(0)
  end

  @spec blank?(string() | nil) :: boolean()
  def blank?(str_or_nil) do
    case str_or_nil do
      "" -> true
      nil -> true
      _ -> false
    end
  end
end
