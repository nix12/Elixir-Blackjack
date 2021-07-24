defmodule BlackjackCLI.Views.Login do
  # Maintain state alternating between password and username with tab
  require Logger

  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  alias Blackjack.{Accounts, Core}
  alias BlackjackCLI.Controllers.AuthenticationController

  @space_bar key(:space)
  @tab key(:tab)
  @enter key(:enter)

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]

  def update(model, msg) do
    case msg do
      {:event, %{key: @tab}} ->
        if Agent.get(:login, fn login -> login.active end) == true do
          Agent.update(:login, fn login ->
            %{active: active} = login
            %{login | active: !active, username: model.input}
          end)

          %{model | input: ""}
        else
          Agent.update(:login, fn login ->
            %{active: active} = login
            %{login | active: !active, password: model.input}
          end)

          %{model | input: ""}
        end

      {:event, %{key: key}} when key in @delete_keys ->
        updated_model = %{model | input: String.slice(model.input, 0..-2)}

        if Agent.get(:login, fn login -> login.active end) == true do
          Agent.update(:login, fn login ->
            %{username: username} = login
            %{login | username: updated_model.input}
          end)

          updated_model
        else
          updated_model = %{model | input: String.slice(model.input, 0..-2)}

          Agent.update(:login, fn login ->
            %{password: password} = login
            %{login | password: updated_model.input}
          end)

          updated_model
        end

      {:event, %{key: @space_bar}} ->
        updated_model = %{model | input: model.input <> " "}

        if Agent.get(:login, fn login -> login.active end) == true do
          Agent.update(:login, fn login ->
            %{username: username} = login
            %{login | username: updated_model.input}
          end)

          updated_model
        else
          updated_model = %{model | input: model.input <> " "}

          Agent.update(:login, fn login ->
            %{password: password} = login
            %{login | password: updated_model.input}
          end)

          updated_model
        end

      {:event, %{ch: ch}} when ch > 0 ->
        updated_model = %{
          model
          | input:
              (model.input |> to_string |> String.replace(~r/^[[:digit:]]+$/, "")) <> <<ch::utf8>>
        }

        if Agent.get(:login, fn login -> login.active end) == true do
          Agent.update(:login, fn login ->
            %{username: username} = login
            %{login | username: updated_model.input}
          end)

          updated_model
        else
          updated_model = %{model | input: model.input <> <<ch::utf8>>}

          Agent.update(:login, fn login ->
            %{password: password} = login
            %{login | password: updated_model.input}
          end)

          updated_model
        end

      {:event, %{key: @enter}} ->
        assigns = %{
          user: %{
            username: Agent.get(:login, fn login -> login.username end),
            password_hash: Agent.get(:login, fn login -> login.password end)
          }
        }

        case AuthenticationController.send_credentials(%Plug.Conn{assigns: assigns}) do
          {:ok, {_, status, _}, token} when status >= 200 and status < 300 ->
            Agent.stop(:login, :normal)
            Accounts.spawn_user(assigns.user.username)
            Core.create_player(assigns.user.username)

            %{
              model
              | screen: :menu,
                token: token,
                input: 0,
                user: %{username: assigns.user.username}
            }

          {:error, msg} ->
            Agent.update(:login, fn login ->
              %{login | error: msg}
            end)

            %{model | screen: :login}

          _ ->
            %{model | screen: :login}
        end

      _ ->
        model
    end
  end

  def render(model) do
    Agent.start_link(
      fn ->
        %{active: true, username: "", password: "", error: ""}
      end,
      name: :login
    )

    view top_bar: label(content: Agent.get(:login, fn login -> login.error end)) do
      panel title: "LOGIN" do
        row do
          column size: 6 do
            panel title: "USERNAME" do
              label do
                text(content: Agent.get(:login, fn login -> login.username end))

                if Agent.get(:login, fn login -> login.active end) == true do
                  text(content: "W", color: :black, background: :white)
                end
              end
            end
          end

          column size: 6 do
            panel title: "PASSWORD" do
              label do
                text(content: Agent.get(:login, fn login -> login.password end))

                if Agent.get(:login, fn login -> login.active end) == false do
                  text(content: "W", color: :black, background: :white)
                end
              end
            end
          end
        end
      end
    end
  end
end
