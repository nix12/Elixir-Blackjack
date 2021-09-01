defmodule BlackjackCLI.Views.ServersTest do
  use Blackjack.RepoCase
  @doctest BlackjackCLI.Views.Servers

  import Ratatouille.Constants, only: [key: 1]

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)
  @tab key(:tab)

  setup do
    Application.stop(:blackjack)
    :ok = Application.start(:blackjack)
  end

  setup do
    [initial_state: %{BlackjackCLI.App.State.init() | screen: :servers}]
  end

  describe "update/2" do
    test "when tab is pressed", %{initial_state: initial_state} do
      assert tab(initial_state)
    end

    test "should move the servers menu down 1 when down arrow is pressed", %{
      initial_state: initial_state
    } do
      assert %{input: -1, user: _, screen: :servers, token: _, data: _} =
               BlackjackCLI.Views.Servers.update(
                 initial_state,
                 {:event, %{key: @down}}
               )
    end

    test "should move menu select down one when s key is pressed", %{
      initial_state: initial_state
    } do
      assert %{input: -1, user: _, screen: :servers, token: _, data: _} =
               BlackjackCLI.Views.Servers.update(%{initial_state | input: 1}, {:event, %{ch: ?s}})
    end

    test "should move menu select up one when up arrow is pressed", %{
      initial_state: initial_state
    } do
      assert %{input: 0, user: _, screen: :servers, token: _, data: _} =
               BlackjackCLI.Views.Servers.update(
                 %{initial_state | input: 1},
                 {:event, %{key: @up}}
               )
    end

    test "should move menu select down one when w key is pressed", %{
      initial_state: initial_state
    } do
      assert %{input: 0, user: _, screen: :servers, token: _, data: _} =
               BlackjackCLI.Views.Servers.update(%{initial_state | input: 1}, {:event, %{ch: ?w}})
    end

    test "should move from servers to server menu", %{
      initial_state: initial_state
    } do
      assert tab(initial_state)

      assert %{input: 0, user: _, screen: :servers, token: _, data: _} =
               BlackjackCLI.Views.Servers.update(initial_state, {:event, nil})
    end

    test "should change screen based on servers menu options", %{initial_state: initial_state} do
      updated_state =
        BlackjackCLI.Views.Servers.update(
          initial_state,
          {:event, %{key: @tab}}
        )

      assert %{input: 0, menu: true, user: _, screen: :servers, token: nil, data: _} =
               BlackjackCLI.Views.Servers.update(
                 updated_state,
                 {:event, nil}
               )

      assert down_menu(updated_state, 0, :create_server)
      assert down_menu(updated_state, 1, :find_server)
      assert down_menu(updated_state, 2, :menu)
    end
  end

  describe "switch_menus/1" do
    test "when :menu is not included in model", %{initial_state: initial_state} do
      assert %{input: 0, menu: true, data: _, user: _, screen: :servers, token: _} =
               BlackjackCLI.Views.Servers.switch_menus(initial_state)
    end

    test "when :menu is included in model", %{initial_state: initial_state} do
      updated_state = BlackjackCLI.Views.Servers.switch_menus(initial_state)

      assert %{input: 0, menu: false, data: _, user: _, screen: :servers, token: _} =
               BlackjackCLI.Views.Servers.switch_menus(%{updated_state | menu: true})
    end
  end

  defp tab(initial_state) do
    %{input: 0, user: _, screen: :servers, token: nil, data: _} =
      BlackjackCLI.Views.Servers.update(
        initial_state,
        {:event, %{key: @tab}}
      )
  end

  def down_menu(initial_state, index, screen) do
    %{input: index, menu: true, user: _, screen: screen, token: _, data: _} =
      BlackjackCLI.Views.Servers.update(
        %{initial_state | input: index, screen: screen},
        {:event, %{key: @down}}
      )
  end
end
