defmodule BlackjackCLI.Views.Search do
  import Ratatouille.View

  alias BlackjackCLI.Controllers.ServersController

  def update(model, msg), do: model

  def render(model) do
    view do
      panel title: "BLACKJACK" do
        row do
          column size: 4 do
            panel title: "POPULAR SERVERS", height: 10 do
              label(content: "PLACEHOLDER")
            end

            panel title: "RECENTS", height: 10 do
              label(content: "PLACEHOLDER")
            end
          end

          column size: 8 do
            panel title: "SERVERS", height: 20 do
              Enum.map(ServersController.get_servers(%Plug.Conn{}), fn server ->
                label(content: "#{server.server_name}")
              end)
            end
          end
        end
      end
    end
  end
end
