defmodule BlackjackCLI.Views.CreateServerTest do
  use Blackjack.RepoCase
  @doctest BlackjackCLI.Views.CreateServer.State
  use Plug.Test

  import BlackjackTest.Helpers
  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCLI.Views.CreateServer.State

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
    [initial_state: %{BlackjackCLI.App.State.init() | screen: :create_server}]
  end

  setup do
    mock_login("username", "password")

    %{registry: Registry.Web}
  end

  setup do
    on_exit(fn ->
      Blackjack.Repo.delete_all(Blackjack.Accounts.User)
    end)
  end

  describe "update/2" do
    test "should delete character", %{initial_state: initial_state} do
      assert delete(initial_state, @delete_keys, 0, State, %{input: "asdf"})
      assert delete(initial_state, @delete_keys, 1, State, %{input: "asdf"})
      assert delete(initial_state, @delete_keys, 2, State, %{input: "asdf"})
    end

    test "should accept space as input", %{initial_state: initial_state} do
      assert key(initial_state, @space_bar, State, %{input: ""})
    end

    test "should take character input", %{initial_state: initial_state} do
      assert input(initial_state, State, %{input: "asdf"})
    end

    test "should create new server and return to :servers screen", %{initial_state: initial_state} do
      assert key(initial_state, @enter, State, %{input: "new server", screen: :servers})
    end
  end
end
