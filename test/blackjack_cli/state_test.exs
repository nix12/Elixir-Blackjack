defmodule BlackjackCLI.App.StateTest do
  use ExUnit.Case, async: true

  import Ratatouille.Constants, only: [key: 1]
  @doctest BlackjackCLI.App.State
  import BlackjackCLI.Views.Registration, only: [start_registration: 0]

  @tab key(:tab)

  setup do
    Application.stop(:blackjack)
    :ok = Application.start(:blackjack)
  end

  setup do
    # start_supervised!({Registry, keys: :unique, name: Registry.WebTest})
    # %{registry: Registry.WebTest}
    pid = Process.whereis(Registry.Web)
    # on_exit(fn -> Process.exit(pid, :kill) end)
    :ok
  end

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

  setup do
    {:ok, pid} =
      Agent.start_link(
        fn ->
          %{
            tab_count: 0,
            # first_name: "",
            # last_name: "",
            username: "",
            password: "",
            password_confirmation: "",
            error: ""
          }
        end,
        name: Blackjack.via_tuple(Registry.Web, :registration)
      )

    on_exit(fn -> Process.exit(pid, :kill) end)

    %{registry: Registry.Web}
  end

  describe "init/0" do
    test "initialize application state" do
      assert %{
               input: 0,
               user: _,
               screen: :start,
               token: nil,
               data: _
             } = BlackjackCLI.App.State.init()
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
                 {:event, %{key: @tab}}
               )
    end
  end
end
