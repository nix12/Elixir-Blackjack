defmodule BlackjackCLI.Views.RegistrationTest do
  use Blackjack.RepoCase
  @doctest BlackjackCLI.Views.Registration.State

  import Ratatouille.Constants, only: [key: 1]

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
    [initial_state: %{BlackjackCLI.App.State.init() | screen: :registration}]
  end

  setup do
    BlackjackCLI.Views.Registration.State.start_registration()

    %{registry: Registry.Web}
  end

  describe "update/2" do
    test "update registration agent username with state after tab", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert Agent.get(Blackjack.via_tuple(registry, :registration), fn registration ->
               registration.tab_count
             end) == 0

      assert username(initial_state)

      assert Agent.get(Blackjack.via_tuple(registry, :registration), fn registration ->
               registration.username
             end) ==
               "username"
    end

    test "update registration agent password with state after tab", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert tab(initial_state)
      assert Agent.get(Blackjack.via_tuple(registry, :registration), & &1.tab_count) == 1
      assert password(initial_state)

      assert Agent.get(Blackjack.via_tuple(registry, :registration), & &1.password) ==
               "password"
    end

    test "update registration agent password confirmation with state after tab", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert tab(initial_state)
      assert password(initial_state)

      assert %{input: "", user: _, screen: :registration, token: nil, data: _} =
               BlackjackCLI.Views.Registration.State.update(
                 %{initial_state | screen: :registration},
                 {:event, %{key: @tab}}
               )

      assert Agent.get(Blackjack.via_tuple(registry, :registration), & &1.tab_count) == 2
      assert password(initial_state)

      assert Agent.get(Blackjack.via_tuple(registry, :registration), & &1.password_confirmation) ==
               "password"

      assert Agent.get(Blackjack.via_tuple(registry, :registration), & &1.password) ==
               Agent.get(Blackjack.via_tuple(registry, :registration), & &1.password_confirmation)
    end

    test "behavior after pressing enter when password and password confirmation match",
         %{initial_state: initial_state, registry: registry} do
      assert username(initial_state)
      assert tab(initial_state)
      assert password(initial_state)
      assert tab(initial_state)
      assert password(initial_state)

      assert %{
               errors: "",
               username: "username",
               password: "password",
               password_confirmation: "password",
               tab_count: 2
             } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)

      assert enter(initial_state, :menu)
    end

    test "behavior after pressing enter when username, password, and password confirmation are empty",
         %{initial_state: initial_state, registry: registry} do
      assert %{input: "", user: _, screen: :registration, token: nil, data: _} =
               BlackjackCLI.Views.Registration.State.update(
                 %{initial_state | input: ""},
                 {:event, nil}
               )

      assert tab(initial_state)

      assert %{input: "", user: _, screen: :registration, token: nil, data: _} =
               BlackjackCLI.Views.Registration.State.update(
                 %{initial_state | input: ""},
                 {:event, nil}
               )

      assert tab(initial_state)

      assert %{input: "", user: _, screen: :registration, token: nil, data: _} =
               BlackjackCLI.Views.Registration.State.update(
                 %{initial_state | input: ""},
                 {:event, nil}
               )

      assert %{
               errors: "",
               username: "",
               password: "",
               password_confirmation: "",
               tab_count: 2
             } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)

      assert %{input: 0, user: _, screen: :registration, token: _, data: _} =
               BlackjackCLI.Views.Registration.State.update(
                 initial_state,
                 {:event, %{key: @enter}}
               )

      assert %{
               errors: "username cannot be blank.",
               username: "",
               password: "",
               password_confirmation: "",
               tab_count: 2
             } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)
    end

    test "behavior after pressing enter when password and password confirmation do not match",
         %{initial_state: initial_state, registry: registry} do
      assert username(initial_state)
      assert tab(initial_state)
      assert password(initial_state)
      assert tab(initial_state)

      assert %{input: "notpassword", user: _, screen: :registration, token: nil, data: _} =
               BlackjackCLI.Views.Registration.State.update(
                 %{initial_state | input: "notpassword"},
                 {:event, nil}
               )

      assert %{
               errors: "",
               username: "username",
               password: "password",
               password_confirmation: "notpassword",
               tab_count: 2
             } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)

      assert %{input: 0, user: _, screen: :registration, token: _, data: _} =
               BlackjackCLI.Views.Registration.State.update(
                 initial_state,
                 {:event, %{key: @enter}}
               )

      assert %{
               errors: "password and password_confirmation must match.",
               username: "username",
               password: "password",
               password_confirmation: "notpassword",
               tab_count: 2
             } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)
    end

    test "character input", %{initial_state: initial_state} do
      assert %{input: "a", user: _, screen: :registration, token: nil, data: _} =
               BlackjackCLI.Views.Registration.State.update(
                 %{initial_state | input: ""},
                 {:event, %{ch: ?a}}
               )
    end

    test "space bar input", %{initial_state: initial_state} do
      assert %{input: " ", user: _, screen: :registration, token: nil, data: _} =
               BlackjackCLI.Views.Registration.State.update(
                 %{initial_state | input: ""},
                 {:event, %{key: @space_bar}}
               )
    end

    test "character deletion", %{initial_state: initial_state} do
      assert delete(initial_state, 0)
      assert delete(initial_state, 1)
      assert delete(initial_state, 2)
    end
  end

  defp username(initial_state, override \\ %{}) do
    %{input: "username", user: _, screen: :registration, token: nil, data: _} =
      BlackjackCLI.Views.Registration.State.update(
        %{initial_state | input: "username"},
        {:event, nil}
      )
  end

  defp password(initial_state, override \\ %{}) do
    %{input: "password", user: _, screen: :registration, token: nil, data: _} =
      BlackjackCLI.Views.Registration.State.update(
        %{initial_state | input: "password"},
        {:event, nil}
      )
  end

  defp tab(initial_state) do
    %{input: "", user: _, screen: :registration, token: nil, data: _} =
      BlackjackCLI.Views.Registration.State.update(
        %{initial_state | screen: :registration},
        {:event, %{key: @tab}}
      )
  end

  def enter(initial_state, screen) do
    %{input: _, user: _, screen: screen, token: _, data: _} =
      BlackjackCLI.Views.Registration.State.update(
        %{initial_state | input: ""},
        {:event, %{key: @enter}}
      )
  end

  defp delete(initial_state, index) do
    %{input: "asd", user: _, screen: :registration, token: nil, data: _} =
      BlackjackCLI.Views.Registration.State.update(
        %{initial_state | input: "asdf"},
        {:event, %{key: @delete_keys |> Enum.at(index)}}
      )
  end
end
