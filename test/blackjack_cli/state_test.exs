defmodule BlackjackCLI.App.StateTest do
  use Blackjack.RepoCase, async: true
  @doctest BlackjackCLI.App.State

  alias BlackjackCLI.Views.Registration

  setup do
    Application.stop(:blackjack)
    :ok = Application.start(:blackjack)
  end

  setup do
    [initial_state: BlackjackCLI.App.State.init()]
  end

  setup do
    Registration.start_registration()
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
    test "change to registration screen", %{
      initial_state: initial_state
    } do
      assert %{
               input: 1,
               user: _,
               screen: :registration,
               token: nil,
               data: _
             } =
               BlackjackCLI.App.State.update(
                 %{initial_state | screen: :registration, input: 1},
                 {:event, nil}
               )
    end
  end
end
