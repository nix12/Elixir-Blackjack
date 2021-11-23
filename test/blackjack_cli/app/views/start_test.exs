defmodule BlackjackCLI.Views.StartTest do
  use Blackjack.RepoCase, async: true
  @doctest BlackjackCLI.Views.Start.State

  import BlackjackTest.Helpers
  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCLI.Views.Start.State

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)

  setup_all do
    Application.stop(:blackjack)
    :ok = Application.start(:blackjack)
  end

  setup do
    [initial_state: BlackjackCLI.App.State.init()]
  end

  describe "update/2" do
    test "should move menu select down one when down arrow is pressed", %{
      initial_state: initial_state
    } do
      assert key(initial_state, @down, State) ==
               %{input: 1, user: nil, screen: :start, token: nil, data: [], menu: true}
    end

    test "should move menu select down one when s key is pressed", %{
      initial_state: initial_state
    } do
      assert input(initial_state, State, %{input: ?s, screen: :start, user: nil}) ==
               %{input: 1, user: nil, screen: :start, token: nil, data: [], menu: true}
    end

    test "should move menu select up one when up arrow is pressed", %{
      initial_state: initial_state
    } do
      assert key(%{initial_state | input: 1}, @up, State) ==
               %{input: 0, user: nil, screen: :start, token: nil, data: [], menu: true}
    end

    test "should move menu select down one when w key is pressed", %{
      initial_state: initial_state
    } do
      assert input(%{initial_state | input: 1}, State, %{input: ?w, screen: :start, user: nil}) ==
               %{input: 0, user: nil, screen: :start, token: nil, data: [], menu: true}
    end

    test "should change screen to :login when selected and enter is pressed", %{
      initial_state: initial_state
    } do
      assert key(initial_state, @enter, State) ==
               %{input: 0, user: nil, screen: :login, token: nil, data: [], menu: false}
    end

    test "should change screen to :registration when selected and enter is pressed", %{
      initial_state: initial_state
    } do
      state = key(initial_state, @down, State)

      assert key(state, @enter, State) ==
               %{input: 1, user: nil, screen: :registration, token: nil, data: [], menu: false}
    end
  end
end
