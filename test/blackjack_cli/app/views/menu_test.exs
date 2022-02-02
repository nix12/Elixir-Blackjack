defmodule BlackjackCli.Views.MenuTest do
  use Blackjack.RepoCase
  @doctest BlackjackCli.Views.Menu.State

  import Blackjack.Helpers
  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCli.Views.Menu.State

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)

  setup_all do
    Application.stop(:blackjack)
    :ok = Application.start(:blackjack)
  end

  setup do
    [initial_state: %{BlackjackCli.App.State.init() | screen: :menu}]
  end

  describe "update/2" do
    test "should move menu select down one when down arrow is pressed", %{
      initial_state: initial_state
    } do
      assert key(initial_state, @down, State) ==
               %{input: 1, user: nil, screen: :menu, token: nil, data: [], menu: true}
    end

    test "should move menu select down one when s key is pressed", %{
      initial_state: initial_state
    } do
      assert input(initial_state, State, %{input: ?s, screen: :menu, user: nil}) ==
               %{input: 1, user: nil, screen: :menu, token: nil, data: [], menu: true}
    end

    test "should move menu select up one when up arrow is pressed", %{
      initial_state: initial_state
    } do
      assert key(%{initial_state | input: 1}, @up, State) ==
               %{input: 0, user: nil, screen: :menu, token: nil, data: [], menu: true}
    end

    test "should move menu select down one when w key is pressed", %{
      initial_state: initial_state
    } do
      assert input(%{initial_state | input: 1}, State, %{input: ?w, screen: :menu, user: nil}) ==
               %{input: 0, user: nil, screen: :menu, token: nil, data: [], menu: true}
    end

    test "change screen when enter is pressed", %{
      initial_state: initial_state
    } do
      {:ok, _resource} =
        build(:custom_user, username: "username")
        |> set_password("password")
        |> insert()

      {:ok, %{"user" => %{"username" => username}}} = mock_login("username", "password")

      assert key(initial_state, @enter, State, %{user: %{username: username}}) ==
               %{
                 input: 0,
                 user: %{username: "username"},
                 screen: :servers,
                 token: nil,
                 data: [],
                 menu: true
               }
    end
  end
end
