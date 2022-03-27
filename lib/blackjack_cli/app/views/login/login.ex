defmodule BlackjackCli.Views.Login do
  @moduledoc """
    Display the view of the login state
  """
  import Ratatouille.View

  alias BlackjackCli.Views.Login.LoginForm

  @type model() :: Map.t()
  @type event() :: {atom(), map()}

  @doc """
    Update login view
  """
  @spec update(model(), event()) :: map()
  def update(model, msg), do: BlackjackCli.Views.Login.State.update(model, msg)

  @doc """
    Renders login view
  """
  @spec render(model()) :: Ratatouille.Renderer.Element.t()
  def render(model) do
    top_bar = label(content: LoginForm.get_field(:errors))

    bottom_bar =
      label(
        content:
          "Press enter after filling out login form or go to login action and press enter to continue."
      )

    tab_count = LoginForm.get_field(:tab_count)

    view top_bar: top_bar, bottom_bar: bottom_bar do
      panel title: "BLACKJACK" do
        panel title: "LOGIN" do
          row do
            column size: 6 do
              panel title: "USERNAME" do
                label do
                  text(content: LoginForm.get_field(:username))

                  if tab_count == 0 do
                    text(content: "W", color: :white, background: :white)
                  end
                end
              end
            end

            column size: 6 do
              panel title: "PASSWORD" do
                label do
                  text(content: LoginForm.get_field(:password))

                  if tab_count == 1 do
                    text(content: "W", color: :white, background: :white)
                  end
                end
              end
            end
          end
        end

        panel title: "ACTIONS", height: 6 do
          row do
            column size: 12 do
              if model.input == 0 and model.menu == true do
                label(content: "Back", background: :white, color: :black)
              else
                label(content: "Back")
              end

              if model.input == 1 and model.menu == true do
                label(content: "Login", background: :white, color: :black)
              else
                label(content: "Login")
              end
            end
          end
        end
      end
    end
  end
end
