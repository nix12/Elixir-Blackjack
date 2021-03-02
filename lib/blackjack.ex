defmodule Blackjack do
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

  def parent(registry, name) do
    [{pid, _}] = Registry.lookup(registry, name)
    pid
  end
end
