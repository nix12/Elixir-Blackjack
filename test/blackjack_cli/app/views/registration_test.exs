defmodule BlackjackCLI.Views.RegistrationTest do
  use Blackjack.RepoCase, async: true
  @doctest BlackjackCLI.Views.Registration

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
    [
      initial_state: %{BlackjackCLI.App.State.init() | screen: :registration}
    ]
  end

  setup do
    BlackjackCLI.Views.Registration.start_registration()

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

      assert Agent.get(Blackjack.via_tuple(registry, :registration), fn registration ->
               registration.tab_count
             end) == 1

      assert password(initial_state)

      assert Agent.get(Blackjack.via_tuple(registry, :registration), fn registration ->
               registration.password
             end) ==
               "password"
    end

    test "update registration agent password confirmation with state after tab", %{
      initial_state: initial_state,
      registry: registry
    } do
      assert tab(initial_state)
      assert password(initial_state)

      assert %{
               input: "",
               user: _,
               screen: :registration,
               token: nil,
               data: _
             } =
               BlackjackCLI.Views.Registration.update(
                 %{initial_state | screen: :registration},
                 {:event, %{key: @tab}}
               )

      assert Agent.get(Blackjack.via_tuple(registry, :registration), fn registration ->
               registration.tab_count
             end) == 2

      assert password(initial_state)

      assert Agent.get(Blackjack.via_tuple(registry, :registration), fn registration ->
               registration.password_confirmation
             end) ==
               "password"

      assert Agent.get(Blackjack.via_tuple(registry, :registration), fn registration ->
               registration.password
             end) ==
               Agent.get(Blackjack.via_tuple(registry, :registration), fn registration ->
                 registration.password_confirmation
               end)
    end

    test "behavior after pressing enter when password and password confirmation match",
         %{initial_state: initial_state, registry: registry} do
      assert username(initial_state)
      assert tab(initial_state)
      assert password(initial_state)
      assert tab(initial_state)
      assert password(initial_state)

      assert %{
               error: "",
               username: "username",
               password: "password",
               password_confirmation: "password",
               tab_count: 2
             } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)

      assert enter(initial_state, :dashboard)
    end

    test "behavior after pressing enter when password and password confirmation do not match",
         %{initial_state: initial_state, registry: registry} do
      assert username(initial_state)
      assert tab(initial_state)
      assert password(initial_state)
      assert tab(initial_state)

      assert %{
               input: "notpassword",
               user: _,
               screen: :registration,
               token: nil,
               data: _
             } =
               BlackjackCLI.Views.Registration.update(
                 %{initial_state | input: "notpassword"},
                 {:event, nil}
               )

      assert %{
               error: "",
               username: "username",
               password: "password",
               password_confirmation: "notpassword",
               tab_count: 2
             } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)

      assert enter(initial_state, :registration)

      assert %{
               error: "Password and password confirmation do not match.",
               username: "username",
               password: "password",
               password_confirmation: "notpassword",
               tab_count: 2
             } = Agent.get(Blackjack.via_tuple(registry, :registration), & &1)
    end

    test "character input", %{initial_state: initial_state} do
      assert %{
               input: "a",
               user: _,
               screen: :registration,
               token: nil,
               data: _
             } =
               BlackjackCLI.Views.Registration.update(
                 %{initial_state | input: ""},
                 {:event, %{ch: ?a}}
               )
    end

    test "space bar input", %{initial_state: initial_state} do
      assert %{
               input: " ",
               user: _,
               screen: :registration,
               token: nil,
               data: _
             } =
               BlackjackCLI.Views.Registration.update(
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

  defp username(initial_state) do
    %{
      input: "username",
      user: _,
      screen: :registration,
      token: nil,
      data: _
    } =
      BlackjackCLI.Views.Registration.update(
        %{initial_state | input: "username"},
        {:event, nil}
      )
  end

  defp password(initial_state) do
    %{
      input: "password",
      user: _,
      screen: :registration,
      token: nil,
      data: _
    } =
      BlackjackCLI.Views.Registration.update(
        %{initial_state | input: "password"},
        {:event, nil}
      )
  end

  defp tab(initial_state) do
    %{
      input: "",
      user: _,
      screen: :registration,
      token: nil,
      data: _
    } =
      BlackjackCLI.Views.Registration.update(
        %{initial_state | screen: :registration},
        {:event, %{key: @tab}}
      )
  end

  def enter(initial_state, screen) do
    %{
      input: "",
      user: _,
      screen: screen,
      token: _,
      data: _
    } =
      BlackjackCLI.Views.Registration.update(
        %{initial_state | input: ""},
        {:event, %{key: @enter}}
      )
  end

  defp delete(initial_state, index) do
    %{
      input: "asd",
      user: _,
      screen: :registration,
      token: nil,
      data: _
    } =
      BlackjackCLI.Views.Registration.update(
        %{initial_state | input: "asdf"},
        {:event, %{key: @delete_keys |> Enum.at(index)}}
      )
  end
end
