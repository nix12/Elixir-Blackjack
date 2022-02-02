defmodule BlackjackCli.Views.LoginTest do
  @doctest BlackjackCli.Views.Login.State
  use Blackjack.RepoCase, async: false

  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCli.Views.Login.{State, LoginForm}

  @space_bar key(:space)
  @tab key(:tab)
  @enter key(:enter)
  @up key(:arrow_up)
  @down key(:arrow_down)

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
    build(:custom_user, username: "username")
    |> set_password("password")
    |> insert()

    :ok
  end

  setup do
    [initial_state: %{BlackjackCli.App.State.init() | screen: :login, menu: false}]
  end

  setup do
    State.start_login()
    %{registry: Registry.App}
  end

  setup do
    on_exit(fn ->
      Blackjack.Repo.delete_all(Blackjack.Accounts.User)
    end)
  end

  describe "update/2" do
    test "update login username and password user with enter", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert input(initial_state, State, %{input: "username"}) ==
               %{input: "username", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert key(initial_state, @tab, State) ==
               %{input: "", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{input: "password", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert %{tab_count: 1, username: "username", password: "password", errors: ""} =
               LoginForm.get_fields()

      IO.inspect(Repo.all(Blackjack.Accounts.User), label: "=====> USERS <=====")
      IO.inspect(LoginForm.get_fields(), label: "=====> FORM FIELDS <=====")
      IO.inspect(initial_state, label: "=====> FORM STATE <=====")

      logged_in_user = key(initial_state, @enter, State)

      assert %{
               input: 0,
               user: %{username: "username"},
               screen: :menu,
               token: _token,
               data: [],
               menu: true
             } = logged_in_user
    end

    test "update login username and password with menu", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert input(initial_state, State, %{input: "username"}) ==
               %{input: "username", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert key(initial_state, @tab, State) ==
               %{input: "", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{input: "password", user: nil, screen: :login, token: nil, data: [], menu: false}

      assert %{tab_count: 1, username: "username", password: "password", errors: ""} =
               LoginForm.get_fields()

      assert %{input: 1, user: nil, screen: :login, token: nil, data: [], menu: false} =
               key(initial_state, @down, State)

      IO.inspect(Repo.all(Blackjack.Accounts.User), label: "=====> USERS <=====")
      IO.inspect(Repo.all(Blackjack.Accounts.User), label: "=====> USERS <=====")
      IO.inspect(LoginForm.get_fields(), label: "=====> FORM FIELDS <=====")
      IO.inspect(initial_state, label: "=====> FORM STATE <=====")

      logged_in_user = key(initial_state, @enter, State)

      assert %{
               input: 0,
               user: %{username: "username"},
               screen: :menu,
               token: _token,
               data: [],
               menu: true
             } = logged_in_user
    end

    test "update login errors from no password or username", %{
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

      assert %{tab_count: 1, username: "", password: "", errors: "username cannot be blank."} =
               LoginForm.get_fields()
    end

    test "update login errors from bad password", %{
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
               tab_count: 1,
               username: "badname",
               password: "notpassword",
               errors: "invalid_credentials"
             } = LoginForm.get_fields()
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

    test "go back to start menu", %{initial_state: initial_state} do
      assert %{input: "", user: nil, screen: :login, token: nil, data: [], menu: false} =
               key(initial_state, @tab, State)

      assert %{input: 0, user: nil, screen: :login, token: nil, data: [], menu: true} =
               key(initial_state, @tab, State)

      assert %{input: 0, user: nil, screen: :login, token: nil, data: [], menu: true} =
               key(initial_state, @enter, State)
    end
  end
end
