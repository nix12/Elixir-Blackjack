defmodule BlackjackCli.Views.RegistrationTest do
  use Blackjack.RepoCase
  @doctest BlackjackCli.Views.Registration.State

  import Blackjack.Helpers
  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCli.Views.Registration.State

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
    [initial_state: %{BlackjackCli.App.State.init() | screen: :registration, menu: false}]
  end

  setup do
    State.start_registration()
    BlackjackCli.Views.Login.State.start_login()

    %{registry: Registry.App}
  end

  setup do
    on_exit(fn ->
      Blackjack.Repo.delete_all(Blackjack.Accounts.User)
    end)
  end

  describe "update/2" do
    test "behavior after pressing enter when password and password confirmation match",
         %{initial_state: initial_state, registry: registry} do
      assert input(initial_state, State, %{input: "username"}) ==
               %{
                 input: "username",
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{
                 input: "password",
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{
                 input: "password",
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert %{
               errors: "",
               username: "username",
               password: "password",
               password_confirmation: "password",
               tab_count: 2
             } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)

      %{token: token} =
        registered_user =
        key(initial_state, @enter, State, %{
          input: 0,
          user: %{username: "username"},
          screen: :login
        })

      assert registered_user ==
               %{
                 input: 0,
                 user: %{username: "username"},
                 screen: :login,
                 token: token,
                 data: [],
                 menu: false
               }
    end

    test "behavior after pressing enter when username, password, and password confirmation are empty",
         %{initial_state: initial_state, registry: registry} do
      assert input(initial_state, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}

      assert input(initial_state, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}

      assert input(initial_state, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}

      assert %{
               errors: "",
               username: "",
               password: "",
               password_confirmation: "",
               tab_count: 2
             } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)

      assert key(initial_state, @enter, State, %{
               input: 0,
               user: nil,
               screen: :registration
             }) ==
               %{
                 input: 0,
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert %{
               errors: "username cannot be blank.",
               username: "",
               password: "",
               password_confirmation: "",
               tab_count: 2
             } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)
    end

    test "behavior after pressing enter when password and password confirmation do not match",
         %{initial_state: initial_state, registry: registry} do
      assert input(initial_state, State, %{input: "username"}) ==
               %{
                 input: "username",
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{
                 input: "password",
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}

      assert input(initial_state, State, %{input: "notpassword"}) ==
               %{
                 input: "notpassword",
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert %{
               errors: "",
               username: "username",
               password: "password",
               password_confirmation: "notpassword",
               tab_count: 2
             } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)

      assert key(initial_state, @enter, State, %{
               input: 0,
               screen: :registration
             }) ==
               %{input: 0, user: nil, screen: :registration, token: nil, data: [], menu: false}

      assert %{
               errors: "password and password_confirmation must match.",
               username: "username",
               password: "password",
               password_confirmation: "notpassword",
               tab_count: 2
             } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)
    end

    test "registration of an already registered user",
         %{initial_state: initial_state, registry: registry} do
      build(:custom_user, username: "username")
      |> set_password("password")
      |> insert()

      assert input(initial_state, State, %{input: "username"}) ==
               %{
                 input: "username",
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{
                 input: "password",
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}

      assert input(initial_state, State, %{input: "password"}) ==
               %{
                 input: "password",
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert %{
               errors: "",
               username: "username",
               password: "password",
               password_confirmation: "password",
               tab_count: 2
             } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)

      assert key(initial_state, @enter, State, %{
               input: "",
               screen: :registration
             }) ==
               %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}
    end

    test "registration of an already registered user, but with wrong password",
         %{initial_state: initial_state, registry: registry} do
      build(:custom_user, username: "username")
      |> set_password("password")
      |> insert()

      assert input(initial_state, State, %{input: "username"}) ==
               %{
                 input: "username",
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}

      assert input(initial_state, State, %{input: "wrongpassword"}) ==
               %{
                 input: "wrongpassword",
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert key(initial_state, @tab, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}

      assert input(initial_state, State, %{input: "wrongpassword"}) ==
               %{
                 input: "wrongpassword",
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert %{
               errors: "",
               username: "username",
               password: "wrongpassword",
               password_confirmation: "wrongpassword",
               tab_count: 2
             } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)

      assert key(initial_state, @enter, State, %{input: ""})
    end

    # test "login failure after redirect",
    #      %{initial_state: initial_state, registry: registry} do
    #   Agent.stop(Blackjack.via_tuple(registry, :login), :normal)

    #   assert input(initial_state, State, %{input: "username"}) ==
    #            %{
    #              input: "username",
    #              user: nil,
    #              screen: :registration,
    #              token: nil,
    #              data: [],
    #              menu: false
    #            }

    #   assert key(initial_state, @tab, State, %{input: ""}) ==
    #            %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}

    #   assert input(initial_state, State, %{input: "password"}) ==
    #            %{
    #              input: "password",
    #              user: nil,
    #              screen: :registration,
    #              token: nil,
    #              data: [],
    #              menu: false
    #            }

    #   assert key(initial_state, @tab, State, %{input: ""}) ==
    #            %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}

    #   assert input(initial_state, State, %{input: "password"}) ==
    #            %{
    #              input: "password",
    #              user: nil,
    #              screen: :registration,
    #              token: nil,
    #              data: [],
    #              menu: false
    #            }

    #   assert %{
    #            errors: "",
    #            username: "username",
    #            password: "password",
    #            password_confirmation: "password",
    #            tab_count: 2
    #          } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)

    #   %{token: token} =
    #     registered_user =
    #     key(initial_state, @enter, State, %{
    #       input: 0,
    #       user: %{username: "username"},
    #       screen: :login
    #     })

    #   assert registered_user ==
    #            %{
    #              input: 0,
    #              user: %{username: "username"},
    #              screen: :login,
    #              token: token,
    #              data: [],
    #              menu: false
    #            }

    #   assert %{
    #            errors: "created account but failed to login due to server error.",
    #            username: "",
    #            password: "",
    #            active: true
    #          } = Agent.get(Blackjack.via_tuple(registry, :login), & &1)
    # end

    test "character input", %{initial_state: initial_state} do
      assert input(initial_state, State, %{input: "a"}) ==
               %{input: "a", user: nil, screen: :registration, token: nil, data: [], menu: false}
    end

    test "space bar input", %{initial_state: initial_state} do
      assert key(initial_state, @space_bar, State, %{input: ""}) ==
               %{input: "", user: nil, screen: :registration, token: nil, data: [], menu: false}
    end

    test "character deletion", %{initial_state: initial_state} do
      assert delete(initial_state, @delete_keys, 0, State, %{input: "asdf"}) ==
               %{
                 input: "asd",
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert delete(initial_state, @delete_keys, 1, State, %{input: "asdf"}) ==
               %{
                 input: "asd",
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }

      assert delete(initial_state, @delete_keys, 2, State, %{input: "asdf"}) ==
               %{
                 input: "asd",
                 user: nil,
                 screen: :registration,
                 token: nil,
                 data: [],
                 menu: false
               }
    end
  end
end
