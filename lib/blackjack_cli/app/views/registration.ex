defmodule BlackjackCLI.Views.Registration do
  @moduledoc """
    Registration form for blackjack application
  """
  require Logger
  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCLI.Controllers.{AuthenticationController, RegistrationsController}

  @registry Registry.Web
  @space_bar key(:space)
  @tab key(:tab)
  @enter key(:enter)

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]

  @doc """
    Updates registration form state based on key and input actions
    and maintains form state by using an Agent
  """
  @spec update(map(), tuple()) :: map()
  def update(model, msg) do
    case msg do
      {:event, %{key: @tab}} ->
        # Agent.get_and_update(
        #   Blackjack.via_tuple(@registry, :registration),
        #   fn %{tab_count: tab_count} = registration ->
        #     {registration,
        #      %{
        #        tab_count: tab_count + 1,
        #        username: "",
        #        password: "",
        #        password_confirmation: "",
        #        error: ""
        #      }}
        #   end
        # )

        Agent.update(
          Blackjack.via_tuple(@registry, :registration),
          fn %{tab_count: tab_count} = registration ->
            %{registration | tab_count: tab_count + 1}
          end
        )

        update_user(%{model | input: ""})

      {:event, %{key: key}} when key in @delete_keys ->
        update_user(%{model | input: String.slice(model.input, 0..-2)})

      {:event, %{key: @space_bar}} ->
        update_user(%{
          model
          | input: (model.input |> to_string |> String.replace(~r/^[[:digit:]]+$/, "")) <> " "
        })

      {:event, %{ch: ch}} when ch > 0 ->
        update_user(%{
          model
          | input:
              (model.input |> to_string |> String.replace(~r/^[[:digit:]]+$/, "")) <>
                <<ch::utf8>>
        })

      {:event, %{key: @enter}} ->
        password = Agent.get(Blackjack.via_tuple(@registry, :registration), & &1.password)

        password_confirmation =
          Agent.get(Blackjack.via_tuple(@registry, :registration), & &1.password_confirmation)

        assigns = %{
          user: %{
            username: Agent.get(Blackjack.via_tuple(@registry, :registration), & &1.username),
            password_hash: password
          }
        }

        if password == password_confirmation do
          case RegistrationsController.send_credentials(%Plug.Conn{assigns: assigns}) do
            {:ok, {_, status, _}, token} when status == 201 ->
              AuthenticationController.send_credentials(%Plug.Conn{assigns: assigns})
              Agent.stop(Blackjack.via_tuple(@registry, :registration), :normal)
              %{model | input: "", screen: :dashboard, token: token}

            {:error, msg} ->
              Agent.update(Blackjack.via_tuple(@registry, :registration), &%{&1 | error: msg})
              %{model | screen: :registration}

            _ ->
              %{model | screen: :registration}
          end
        else
          Agent.update(
            Blackjack.via_tuple(@registry, :registration),
            &%{&1 | error: "Password and password confirmation do not match."}
          )

          %{model | screen: :registration}
        end

      _ ->
        IO.inspect(model, label: "MODEL MODEL MODEL")
        update_user(model)
    end
  end

  def render(_model) do
    view top_bar:
           label(content: Agent.get(Blackjack.via_tuple(@registry, :registration), & &1.error)) do
      panel title: "Register" do
        row do
          column size: 12 do
            panel title: "USERNAME" do
              label do
                text(
                  content:
                    Agent.get(Blackjack.via_tuple(@registry, :registration), fn registration ->
                      registration.username
                    end)
                )

                if Agent.get(Blackjack.via_tuple(@registry, :registration), fn registration ->
                     registration.tab_count
                   end) == 0 do
                  text(content: "W", color: :white, background: :white)
                end
              end
            end
          end
        end

        row do
          column size: 6 do
            panel title: "PASSWORD" do
              label do
                text(
                  content:
                    Agent.get(Blackjack.via_tuple(@registry, :registration), fn registration ->
                      registration.password
                    end)
                )

                if Agent.get(Blackjack.via_tuple(@registry, :registration), fn registration ->
                     registration.tab_count
                   end) == 1 do
                  text(content: "W", color: :white, background: :white)
                end
              end
            end
          end

          column size: 6 do
            panel title: "PASSWORD CONFIRMATION" do
              label do
                text(
                  content:
                    Agent.get(Blackjack.via_tuple(@registry, :registration), fn registration ->
                      registration.password_confirmation
                    end)
                )

                if Agent.get(Blackjack.via_tuple(@registry, :registration), fn registration ->
                     registration.tab_count
                   end) == 2 do
                  text(content: "W", color: :white, background: :white)
                end
              end
            end
          end
        end
      end
    end
  end

  @doc """
    Starts a process for maintianing registration form state
  """
  @spec start_registration :: :ok
  def start_registration do
    {:ok, _pid} =
      Agent.start_link(
        fn ->
          %{
            tab_count: 0,
            username: "",
            password: "",
            password_confirmation: "",
            error: ""
          }
        end,
        name: Blackjack.via_tuple(@registry, :registration)
      )

    :ok
  end

  @doc """
    Updates registration process and registrionan model
  """
  @spec update_user(map()) :: map()
  defp update_user(%{input: input, screen: screen} = model) do
    tab_count =
      Agent.get(Blackjack.via_tuple(@registry, :registration), fn %{
                                                                    tab_count: tab_count,
                                                                    username: _,
                                                                    password: _,
                                                                    password_confirmation: _,
                                                                    error: _
                                                                  } ->
        tab_count
      end)

    case tab_count do
      0 ->
        Agent.update(
          Blackjack.via_tuple(@registry, :registration),
          fn registration ->
            %{registration | username: input}
          end
        )

        %{model | input: input, screen: screen}

      1 ->
        Agent.update(
          Blackjack.via_tuple(@registry, :registration),
          fn registration ->
            %{registration | password: input}
          end
        )

        %{model | input: input, screen: screen}

      2 ->
        Agent.update(
          Blackjack.via_tuple(@registry, :registration),
          fn registration ->
            %{registration | password_confirmation: input}
          end
        )

        %{model | input: input, screen: screen}

      _ ->
        Agent.update(
          Blackjack.via_tuple(@registry, :registration),
          fn registration ->
            %{registration | tab_count: 0}
          end
        )

        model
    end
  end
end
