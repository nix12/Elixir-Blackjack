defmodule BlackjackTest.Helpers do
  def mock_user(username, password) do
    {:ok, {_status, _meta, resource}} =
      :httpc.request(
        :post,
        {'http://localhost:4000/register', [], 'application/json',
         Jason.encode!(%{user: %{username: username, password_hash: password}})},
        [],
        []
      )

    {:ok, resource}
  end

  def mock_login(username, password) do
    {:ok, {_status, _meta, resource}} =
      :httpc.request(
        :post,
        {'http://localhost:4000/login', [], 'application/json',
         Jason.encode!(%{user: %{username: username, password_hash: password}})},
        [],
        []
      )

    {:ok, Jason.decode!(resource)}
  end

  def mock_server(server_name) do
    :httpc.request(
      :post,
      {"http://localhost:4000/server/create", [], 'application/json',
       Jason.encode!(%{server_name: server_name})},
      [],
      []
    )
  end

  def input(initial_state, module_state, override \\ %{})

  @spec input(%{:input => any, optional(any) => any}, any) :: any
  def input(initial_state, module_state, override) when override.input |> is_bitstring do
    charlist = override.input |> to_charlist |> tap(&IO.inspect(&1, label: "CHARLIST"))
    state = Map.merge(initial_state, override)
    state = %{state | input: ""}

    for ch <- charlist do
      module_state.update(state, {:event, %{ch: ch}})
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

  def input(initial_state, module_state, override) when override.input |> is_integer do
    charlist = override.input |> tap(&IO.inspect(&1, label: "CHARLIST"))
    state = Map.merge(initial_state, override)
    state = %{state | input: 0}

    %{input: _input, user: _user, screen: _screen, token: _token, data: _data, menu: _menu} =
      module_state.update(state, {:event, %{ch: charlist}})
  end

  def key(initial_state, key, module_state, override \\ %{}) do
    state = Map.merge(initial_state, override)

    returned_state =
      %{input: _input, user: _user, screen: _screen, token: _token, data: _data, menu: _menu} =
      module_state.update(state, {:event, %{key: key}})
      |> tap(&IO.inspect(&1, label: "RETURNED STATE"))

    Map.merge(returned_state, override)
  end

  @spec delete(map, any, integer, atom, map) :: boolean
  def delete(initial_state, delete_keys, index, module_state, override \\ %{}) do
    state = Map.merge(initial_state, override)

    %{input: input, user: _user, screen: _screen, token: _token, data: _data} =
      module_state.update(
        state,
        {:event, %{key: delete_keys |> Enum.at(index)}}
      )
  end
end
