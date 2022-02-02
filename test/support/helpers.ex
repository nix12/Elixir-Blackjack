defmodule Blackjack.Helpers do
  require Logger

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

  def input(initial_state, module, override \\ %{})

  def input(initial_state, module, override) when override.input |> is_bitstring do
    charlist =
      override.input
      |> to_charlist
      |> tap(&IO.inspect(&1, label: "CHARLIST"))

    # Update intial_state with an empty input so the initial input is not include in the test.
    state =
      Map.merge(initial_state, %{override | input: ""})
      |> tap(&IO.inspect(&1, label: "STATE"))

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
    charlist = override.input |> tap(&IO.inspect(&1, label: "CHARLIST"))
    state = Map.merge(initial_state, %{override | input: 0})

    module.update(state, {:event, %{ch: charlist}})
  end

  def key(initial_state, key, module, override \\ %{}) do
    state = Map.merge(initial_state, override)
    IO.inspect(initial_state, label: "INITIAL STATE KEY")

    returned_state =
      module.update(state, {:event, %{key: key}})
      |> tap(&IO.inspect(&1, label: "RETURNED STATE"))

    Map.merge(returned_state, override)
    |> tap(&IO.inspect(&1, label: "MERGED KEY STATE"))
  end

  def delete(initial_state, delete_keys, index, module, override \\ %{}) do
    state = Map.merge(initial_state, override)

    module.update(state, {:event, %{key: delete_keys |> Enum.at(index)}})
  end

  # User Behaviour
  # def get_user(user_params) do
  #   IO.inspect("GET USER")
  #   user_impl().get_user(user_params) |> tap(&IO.inspect(&1, label: "GET USER"))
  # end

  # defp user_impl() do
  #   IO.inspect("USER IMPL")
  #   Application.get_env(:blackjack, :user, UserImpl) |> tap(&IO.inspect("GET USER IMPL: #{&1}"))
  # end
end
