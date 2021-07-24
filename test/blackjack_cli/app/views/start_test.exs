defmodule BlackjackCLI.Views.StartTest do
  use ExUnit.Case, async: true

  import Ratatouille.Constants, only: [key: 1]
  import BlackjackCLI.Views.Start

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)

  # setup do
  #   Application.stop(:blackjack)
  #   :ok = Application.start(:blackjack)
  # end

  setup do
    [
      initial_state: %{
        input: 0,
        user: %{
          username: ""
        },
        screen: :start,
        token: nil,
        data: nil
      }
    ]
  end

  describe "update/2" do
    test "should move menu select down one when down arrow is pressed", %{
      initial_state: initial_state
    } do
      assert update(initial_state, {:event, %{key: @down}}) == %{initial_state | input: 1}
    end

    test "should move menu select down one when s key is pressed", %{
      initial_state: initial_state
    } do
      assert update(initial_state, {:event, %{ch: ?s}}) == %{initial_state | input: 1}
    end

    test "should move menu select up one when up arrow is pressed", %{
      initial_state: initial_state
    } do
      assert update(%{initial_state | input: 1}, {:event, %{key: @up}}) == %{
               initial_state
               | input: 0
             }
    end

    test "should move menu select down one when w key is pressed", %{
      initial_state: initial_state
    } do
      assert update(%{initial_state | input: 1}, {:event, %{ch: ?w}}) == %{
               initial_state
               | input: 0
             }
    end

    test "change screen when enter is pressed", %{
      initial_state: initial_state
    } do
      assert update(initial_state, {:event, %{key: @enter}}) == %{initial_state | screen: :login}
    end

    test "should return state for all other input", %{
      initial_state: initial_state
    } do
      assert update(initial_state, nil) == initial_state
    end
  end
end
