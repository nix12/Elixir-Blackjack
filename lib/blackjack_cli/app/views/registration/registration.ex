defmodule BlackjackCLI.Views.Registration do
  @moduledoc """
    Registration form for blackjack application
  """

  import Ratatouille.View

  alias BlackjackCLI.Views.Registration.State

  @registry Registry.Web

  def update(model, msg), do: State.update(model, msg)

  def render(_model) do
    view top_bar:
           label(content: Agent.get(Blackjack.via_tuple(@registry, :registration), & &1.errors)) do
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
end
