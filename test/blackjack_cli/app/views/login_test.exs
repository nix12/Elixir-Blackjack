defmodule BlackjackCLI.Views.LoginTest do
  use Blackjack.RepoCase
  @doctest BlackjackCLI.Views.Login.State
  use Plug.Test

  import BlackjackTest.Helpers
  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCLI.Views.Login.State

  @space_bar key(:space)
  @tab key(:tab)
  @enter key(:enter)

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]

  setup_all do
    Application.stop(:blackjack)
    :ok = Application.start(:blackjack)
  end

  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Blackjack.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Blackjack.Repo, {:shared, self()})
  end

  setup do
    mock_user("username", "password")
    :ok
  end

  setup do
    [initial_state: %{BlackjackCLI.App.State.init() | screen: :login, menu: false}]
  end

  setup do
    State.start_login()

    %{registry: Registry.Web}
  end

  setup do
    on_exit(fn ->
      Blackjack.Repo.delete_all(Blackjack.Accounts.User)
    end)
  end

  describe "update/2" do
    test "update login agent username and password", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert input(initial_state, State, %{input: "username"}) ==
               %{input: "username", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert key(initial_state, @tab, State) ==
               %{input: "", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{input: "password", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert %{active: false, username: "username", password: "password", errors: ""} =
               Agent.get(Blackjack.via_tuple(registry, :login), & &1)

      %{token: token} = logged_in_user = key(initial_state, @enter, State)

      %{
        input: 0,
        user: %{username: "username"},
        screen: :menu,
        token: token,
        data: [],
        menu: true
      } = logged_in_user
    end

    test "update agent login errors from no password or username", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert input(initial_state, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert input(initial_state, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert key(initial_state, @enter, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert %{active: false, username: "", password: "", errors: "username cannot be blank."} =
               Agent.get(Blackjack.via_tuple(registry, :login), & &1)
    end

    test "update agent login errors from bad password", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert input(initial_state, State, %{input: "badname"}) ==
               %{input: "badname", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert input(initial_state, State, %{input: "notpassword"}) ==
               %{
                 input: "notpassword",
                 user: nil,
                 screen: :login,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert key(initial_state, @enter, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert %{
               active: false,
               username: "badname",
               password: "notpassword",
               errors: "invalid_credentials"
             } = Agent.get(Blackjack.via_tuple(registry, :login), & &1)
    end

    test "character input", %{initial_state: initial_state} do
      assert input(initial_state, State, %{input: "a", screen: :login}) ==
               %{input: "a", user: nil, screen: :login, token: nil, data: [], menu: false}
    end

    test "space bar input", %{initial_state: initial_state} do
      assert key(initial_state, @space_bar, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :login, token: nil, data: [], menu: false}
    end

    test "character deletion", %{initial_state: initial_state} do
      assert delete(initial_state, @delete_keys, 0, State, %{input: "asdf"}) ==
               %{input: "asd", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert delete(initial_state, @delete_keys, 1, State, %{input: "asdf"}) ==
               %{input: "asd", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert delete(initial_state, @delete_keys, 2, State, %{input: "asdf"}) ==
               %{input: "asd", user: nil, screen: :login, token: nil, data: [], menu: false}
    end
  end
end
