defmodule BlackjackCli.Views.Registration do
  @moduledoc """
    Registration form for blackjack application
  """

  import Ratatouille.View

  alias BlackjackCli.Views.Registration.State

  @registry Registry.App

  def update(model, msg), do: State.update(model, msg)

  def render(model) do
    top_bar =
      label(content: Agent.get(Blackjack.via_tuple(@registry, :registration), & &1.errors))

    bottom_bar =
      label(
        content:
          "Press enter after filling out registration form or go to register action and press enter to continue."
      )

    view top_bar: top_bar, bottom_bar: bottom_bar do
      panel title: "BLACKJACK" do
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

        panel title: "ACTIONS", height: 6 do
          row do
            column size: 12 do
              if model.input == 0 and model.menu == true do
                label(content: "Back", background: :white, color: :black)
              else
                label(content: "Back")
              end

              if model.input == 1 and model.menu == true do
                label(content: "Register", background: :white, color: :black)
              else
                label(content: "Register")
              end
            end
          end
        end
      end
    end
  end
end
