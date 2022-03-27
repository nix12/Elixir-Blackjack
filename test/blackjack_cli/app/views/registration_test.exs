defmodule BlackjackCli.Views.RegistrationTest do
  use Blackjack.RepoCase, async: false
  @doctest BlackjackCli.Views.Registration.State

  import Blackjack.Helpers
  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCli.Views.Registration.{State, RegistrationForm}
  alias BlackjackCli.Views.Login.LoginForm
  alias Blackjack.Accounts.User

  @space_bar key(:space)
  @tab key(:tab)
  @enter key(:enter)

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]

  setup do
    [initial_state: %{BlackjackCli.App.State.init() | screen: :registration, menu: false}]
  end

  setup do
    State.start_registration()
    BlackjackCli.Views.Login.State.start_login()

    %{registry: Registry.App}
  end

  describe "update/2" do
    test "behavior after pressing enter when password and password confirmation match",
         %{initial_state: initial_state, registry: registry} do
      IO.inspect("==========================> START")

      assert input(initial_state, State, %{input: "username"}) ==
               %{
                 input: "username",
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{
                 input: "password",
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{
                 input: "password",
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert %{
               errors: "",
               username: "username",
               password: "password",
               password_confirmation: "password",
               tab_count: 2
             } = RegistrationForm.get_fields()

      registered_user = key(initial_state, @enter, State)

      assert %{
               input: 0,
               user: %{username: "username"},
               screen: :menu,
               token: _token,
               data: [],
               menu: false
             } = registered_user
    end

    test "behavior after pressing enter when username, password, and password confirmation are empty",
         %{initial_state: initial_state, registry: registry} do
      assert input(initial_state, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert %{
               errors: "",
               username: "",
               password: "",
               password_confirmation: "",
               tab_count: 2
             } = RegistrationForm.get_fields()

      assert key(initial_state, @enter, State, %{
               input: 0,
               user: nil,
               screen: :registration
             }) ==
               %{
                 input: 0,
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert %{
               errors: "username cannot be blank.",
               username: "",
               password: "",
               password_confirmation: "",
               tab_count: 2
             } = RegistrationForm.get_fields()
    end

    test "behavior after pressing enter when password and password confirmation do not match",
         %{initial_state: initial_state, registry: registry} do
      assert input(initial_state, State, %{input: "username"}) ==
               %{
                 input: "username",
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{
                 input: "password",
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "notpassword"}) ==
               %{
                 input: "notpassword",
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert %{
               errors: "",
               username: "username",
               password: "password",
               password_confirmation: "notpassword",
               tab_count: 2
             } = RegistrationForm.get_fields()

      assert key(initial_state, @enter, State, %{
               input: 0,
               screen: :registration
             }) ==
               %{input: 0, user: nil, screen: :registration, token: "", data: [], menu: false}

      assert %{
               errors: "password and password_confirmation must match.",
               username: "username",
               password: "password",
               password_confirmation: "notpassword",
               tab_count: 2
             } = RegistrationForm.get_fields()
    end

    test "registration of an already registered user",
         %{initial_state: initial_state, registry: registry} do
      build(:custom_user) |> User.insert()

      assert input(initial_state, State, %{input: "username"}) ==
               %{
                 input: "username",
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{
                 input: "password",
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{
                 input: "password",
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert %{
               errors: "",
               username: "username",
               password: "password",
               password_confirmation: "password",
               tab_count: 2
             } = RegistrationForm.get_fields()

      failed_registration = key(initial_state, @enter, State)

      assert %{
               input: "",
               user: nil,
               screen: :registration,
               token: "",
               data: [],
               menu: false
             } = failed_registration
    end

    test "registration of an already registered user, but with wrong password",
         %{initial_state: initial_state, registry: registry} do
      build(:custom_user) |> User.insert()

      assert input(initial_state, State, %{input: "username"}) ==
               %{
                 input: "username",
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "wrongpassword"}) ==
               %{
                 input: "wrongpassword",
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}

      assert input(initial_state, State, %{input: "wrongpassword"}) ==
               %{
                 input: "wrongpassword",
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert %{
               errors: "",
               username: "username",
               password: "wrongpassword",
               password_confirmation: "wrongpassword",
               tab_count: 2
             } = RegistrationForm.get_fields()

      assert key(initial_state, @enter, State)
    end

    test "character input", %{initial_state: initial_state} do
      assert input(initial_state, State, %{input: "a"}) ==
               %{input: "a", user: nil, screen: :registration, token: "", data: [], menu: false}
    end

    test "space bar input", %{initial_state: initial_state} do
      assert key(initial_state, @space_bar, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: "", data: [], menu: false}
    end

    test "character deletion", %{initial_state: initial_state} do
      assert delete(initial_state, State, %{input: "asdf"}) ==
               %{
                 input: "",
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert delete(initial_state, State, %{input: "asdf"}) ==
               %{
                 input: "",
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }

      assert delete(initial_state, State, %{input: "asdf"}) ==
               %{
                 input: "",
                 user: nil,
                 screen: :registration,
                 token: "",
                 data: [],
                 menu: false
               }
    end
  end
end
