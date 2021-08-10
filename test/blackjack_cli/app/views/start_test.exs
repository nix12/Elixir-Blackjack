defmodule BlackjackCLI.Views.StartTest do
  use Blackjack.RepoCase, async: true
  @doctest BlackjackCLI.Views.Start

  import Ratatouille.Constants, only: [key: 1]

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)

  setup do
    Application.stop(:blackjack)
    :ok = Application.start(:blackjack)
  end

  setup do
    [initial_state: %{BlackjackCLI.App.State.init() | screen: :start}]
  end

  describe "update/2" do
    test "should move menu select down one when down arrow is pressed", %{
      initial_state: initial_state
    } do
      assert %{input: 1, user: _, screen: :start, token: nil, data: _} =
               BlackjackCLI.Views.Start.update(initial_state, {:event, %{key: @down}})
    end

    test "should move menu select down one when s key is pressed", %{
      initial_state: initial_state
    } do
      assert %{input: 1, user: _, screen: :start, token: nil, data: _} =
               BlackjackCLI.Views.Start.update(initial_state, {:event, %{ch: ?s}})
    end

    test "should move menu select up one when up arrow is pressed", %{
      initial_state: initial_state
    } do
      assert %{input: 0, user: _, screen: :start, token: nil, data: _} =
               BlackjackCLI.Views.Start.update(%{initial_state | input: 1}, {:event, %{key: @up}})
    end

    test "should move menu select down one when w key is pressed", %{
      initial_state: initial_state
    } do
      assert %{input: 0, user: _, screen: :start, token: nil, data: _} =
               BlackjackCLI.Views.Start.update(%{initial_state | input: 1}, {:event, %{ch: ?w}})
    end

    test "change screen when enter is pressed", %{
      initial_state: initial_state
    } do
      %{input: 1, user: _, screen: :registration, token: nil, data: _} =
        BlackjackCLI.Views.Start.update(%{initial_state | input: 1}, {:event, %{key: @enter}})
    end

    test "should return state for all other input", %{
      initial_state: initial_state
    } do
      assert %{input: 0, user: _, screen: :start, token: nil, data: _} =
               BlackjackCLI.Views.Start.update(initial_state, {:event, nil})
    end
  end
end
