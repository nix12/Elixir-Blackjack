defmodule BlackjackCLI.Views.RegistrationTest do
  use ExUnit.Case, async: true
  use Supervisor

  import Ratatouille.Constants, only: [key: 1]
  @doctest BlackjackCLI.Views.Registration

  @space_bar key(:space)
  @tab key(:tab)
  @enter key(:enter)

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]

  setup do
    Application.stop(:blackjack)
    :ok = Application.start(:blackjack)
  end

  setup do
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
        screen: :registration,
        token: nil,
        data: nil
      }
    ]
  end

  # setup do
  #   IO.inspect(Process.alive?(Registry.Web), label: "alive 1")
  #   r = Registry.Web |> Process.whereis()
  #   IO.inspect(r, label: "registry")
  #   IO.inspect(Process.alive?(r), label: "alive 2")
  #   %{r: r}
  # end

  setup do
    IO.inspect(Process.whereis(Registry.Web), label: "pid")

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

  describe "update/2" do
    test "change input field when tab is pressed", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert Agent.get(Blackjack.via_tuple(registry, :registration), fn registration ->
               registration.tab_count
             end) == 0

      assert %{
               input: 0,
               user: _,
               screen: :registration,
               token: nil,
               data: _
             } = BlackjackCLI.Views.Registration.update(initial_state, {:event, %{key: @tab}})

      assert Agent.get(Blackjack.via_tuple(registry, :registration), fn registration ->
               registration.tab_count
             end) == 1
    end

    test "update registration agent username with state after tab", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert %{
               input: "password",
               user: _,
               screen: :registration,
               token: nil,
               data: _
             } =
               BlackjackCLI.Views.Registration.update(
                 %{initial_state | input: "password"},
                 {:event, %{key: @tab}}
               )

      assert Agent.get(Blackjack.via_tuple(registry, :registration), fn registration ->
               registration.tab_count
             end) == 1

      assert Agent.get(Blackjack.via_tuple(registry, :registration), fn registration ->
               registration.password
             end) ==
               "password"
    end
  end
end
