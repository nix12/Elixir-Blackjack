defmodule BlackjackCLI.App.StateTest do
  use Blackjack.RepoCase
  @doctest BlackjackCLI.App.State

  setup do
    Application.stop(:blackjack)
    :ok = Application.start(:blackjack)
  end

  setup do
    [initial_state: BlackjackCLI.App.State.init()]
  end

  setup do
    BlackjackCLI.Views.Login.State.start_login()
    BlackjackCLI.Views.Registration.State.start_registration()
    %{registry: Registry.Web}
  end

  describe "init/0" do
    test "initialize application state", %{initial_state: initial_state} do
      assert %{
               input: 0,
               user: %{
                 username: ""
               },
               screen: :start,
               token: nil,
               data: _
             } = initial_state
    end
  end

  describe "update/2" do
    test "change screens", %{
      initial_state: initial_state
    } do
      assert screen(initial_state, :start)
      assert screen(initial_state, :login)
      assert screen(initial_state, :registration)
      assert screen(initial_state, :account)
      assert screen(initial_state, :server)
      assert screen(initial_state, :servers)
      assert screen(initial_state, :create_server)
      assert screen(initial_state, :games)
      assert screen(initial_state, :search)
      assert screen(initial_state, :dashboard)
      assert screen(initial_state, :menu)
    end
  end

  defp screen(initial_state, screen) do
    %{
      input: _,
      user: _,
      screen: screen,
      token: nil,
      data: _
    } =
      BlackjackCLI.App.State.update(
        %{initial_state | screen: screen},
        {:event, nil}
      )
  end
end
