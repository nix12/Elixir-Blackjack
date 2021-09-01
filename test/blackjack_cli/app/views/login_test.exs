defmodule BlackjackCLI.Views.LoginTest do
  use Blackjack.RepoCase
  @doctest BlackjackCLI.Views.Login.State

  import Ratatouille.Constants, only: [key: 1]

  @space_bar key(:space)
  @tab key(:tab)
  @enter key(:enter)

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]

  setup do
    Application.stop(:blackjack)
    :ok = Application.start(:blackjack)
  end

  setup do
    [initial_state: %{BlackjackCLI.App.State.init() | screen: :login}]
  end

  setup do
    BlackjackCLI.Views.Login.State.start_login()
    %{registry: Registry.Web}
  end

  describe "update/2" do
    test "update login agent username with state", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert Agent.get(Blackjack.via_tuple(registry, :login), & &1.active) == true
      assert username(initial_state)
      assert Agent.get(Blackjack.via_tuple(registry, :login), & &1.username) == "username"
    end

    test " update login agent password with state", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert tab(initial_state)
      assert Agent.get(Blackjack.via_tuple(registry, :login), & &1.active) == false
      assert password(initial_state)
      assert Agent.get(Blackjack.via_tuple(registry, :login), & &1.password) == "password"
    end

    test "update login agent username and password", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert Agent.get(Blackjack.via_tuple(registry, :login), & &1.active) == true
      assert username(initial_state)
      assert Agent.get(Blackjack.via_tuple(registry, :login), & &1.username) == "username"
      assert tab(initial_state)
      assert Agent.get(Blackjack.via_tuple(registry, :login), & &1.active) == false
      assert password(initial_state)
      assert Agent.get(Blackjack.via_tuple(registry, :login), & &1.password) == "password"

      assert %{active: false, username: "username", password: "password", errors: ""} =
               Agent.get(Blackjack.via_tuple(registry, :login), & &1)

      IO.inspect(Agent.get(Blackjack.via_tuple(registry, :login), & &1),
        label: "INITIAL STATE FROM LOGIN"
      )

      assert enter(initial_state, :menu)
    end

    test "update agent login errors from no password or username", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert %{input: "", user: _, screen: :login, token: nil, data: _} =
               BlackjackCLI.Views.Login.State.update(
                 %{initial_state | input: ""},
                 {:event, nil}
               )

      tab(initial_state)

      assert %{input: "", user: _, screen: :login, token: nil, data: _} =
               BlackjackCLI.Views.Login.State.update(
                 %{initial_state | input: ""},
                 {:event, nil}
               )

      assert %{active: false, username: "", password: "", errors: ""} =
               Agent.get(Blackjack.via_tuple(registry, :login), & &1)

      assert enter(initial_state, :login)
    end

    test "update agent login errors from bad password", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert %{input: "badname", user: _, screen: :login, token: nil, data: _} =
               BlackjackCLI.Views.Login.State.update(
                 %{initial_state | input: "badname"},
                 {:event, nil}
               )

      tab(initial_state)

      assert %{input: "notpassword", user: _, screen: :login, token: nil, data: _} =
               BlackjackCLI.Views.Login.State.update(
                 %{initial_state | input: "notpassword"},
                 {:event, nil}
               )

      assert %{active: false, username: "badname", password: "notpassword", errors: ""} =
               Agent.get(Blackjack.via_tuple(registry, :login), & &1)

      assert enter(initial_state, :login)
    end

    test "character input", %{initial_state: initial_state} do
      assert %{input: "a", user: _, screen: :login, token: nil, data: _} =
               BlackjackCLI.Views.Login.State.update(
                 %{initial_state | input: ""},
                 {:event, %{ch: ?a}}
               )
    end

    test "space bar input", %{initial_state: initial_state} do
      assert %{input: " ", user: _, screen: :login, token: nil, data: _} =
               BlackjackCLI.Views.Login.State.update(
                 %{initial_state | input: ""},
                 {:event, %{key: @space_bar}}
               )
    end

    test "character deletion", %{initial_state: initial_state} do
      assert delete(initial_state, 0)
      assert delete(initial_state, 1)
      assert delete(initial_state, 2)
    end
  end

  defp username(initial_state) do
    %{input: "username", user: _, screen: :login, token: nil, data: _} =
      BlackjackCLI.Views.Login.State.update(
        %{initial_state | input: "username"},
        {:event, nil}
      )
  end

  defp password(initial_state) do
    %{input: "password", user: _, screen: :login, token: nil, data: _} =
      BlackjackCLI.Views.Login.State.update(
        %{initial_state | input: "password"},
        {:event, nil}
      )
  end

  defp tab(initial_state) do
    %{input: "", user: _, screen: :login, token: nil, data: _} =
      BlackjackCLI.Views.Login.State.update(
        %{initial_state | screen: :login},
        {:event, %{key: @tab}}
      )
  end

  def enter(initial_state, screen) do
    %{input: _, user: _, screen: screen, token: _, data: _} =
      BlackjackCLI.Views.Login.State.update(
        %{initial_state | input: ""},
        {:event, %{key: @enter}}
      )
  end

  defp delete(initial_state, index) do
    %{input: "asd", user: _, screen: :login, token: nil, data: _} =
      BlackjackCLI.Views.Login.State.update(
        %{initial_state | input: "asdf"},
        {:event, %{key: @delete_keys |> Enum.at(index)}}
      )
  end
end
