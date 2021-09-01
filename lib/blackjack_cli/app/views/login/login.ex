defmodule BlackjackCLI.Views.Login do
  # Maintain state alternating between password and username with tab
  import Ratatouille.View

  @registry Registry.Web

  def update(model, msg), do: BlackjackCLI.Views.Login.State.update(model, msg)

  @spec render(any) :: Ratatouille.Renderer.Element.t()
  def render(_model) do
    view top_bar: label(content: Agent.get(Blackjack.via_tuple(@registry, :login), & &1.errors)) do
      panel title: "LOGIN" do
        row do
          column size: 6 do
            panel title: "USERNAME" do
              label do
                text(content: Agent.get(Blackjack.via_tuple(@registry, :login), & &1.username))

                if Agent.get(Blackjack.via_tuple(@registry, :login), & &1.active) ==
                     true do
                  text(content: "W", color: :white, background: :white)
                end
              end
            end
          end

          column size: 6 do
            panel title: "PASSWORD" do
              label do
                text(content: Agent.get(Blackjack.via_tuple(@registry, :login), & &1.password))

                if Agent.get(Blackjack.via_tuple(@registry, :login), & &1.active) ==
                     false do
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
