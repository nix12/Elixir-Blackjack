defmodule Blackjack.Helpers do
  def input(initial_state, module, override \\ %{})

  def input(initial_state, module, override) when override.input |> is_bitstring do
    charlist = override.input |> to_charlist
    # Update intial_state with an empty input so the initial input is not include in the test.
    state = Map.merge(initial_state, %{override | input: ""})

    for ch <- charlist do
      module.update(state, {:event, %{ch: ch}})
    end
    |> Enum.reduce(
      state,
      fn map, acc ->
        Map.merge(acc, map, fn k, v1, v2 ->
          if k == :input, do: v1 <> v2, else: v2
        end)
      end
    )
  end

  def input(initial_state, module, override) when override.input |> is_integer do
    charlist = override.input
    state = Map.merge(initial_state, %{override | input: 0})

    module.update(state, {:event, %{ch: charlist}})
  end

  def key(initial_state, key, module, override \\ %{}) do
    state = Map.merge(initial_state, override)
    returned_state = module.update(state, {:event, %{key: key}})

    Map.merge(returned_state, override)
  end

  def delete(initial_state, module, override \\ %{}) do
    state = Map.merge(initial_state, override)

    module.update(state, {:event, %{key: 65522}})
  end
end
