defmodule BlackjackCLI.Views.Server do
  require Logger

  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  alias Ratatouille.Runtime.Command
  alias Blackjack.Core

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)
  @tab key(:tab)

  def update(model, msg) do
    # {:ok, {_, _, server}} = model.data
    # server = server |> Jason.decode!()

    case msg do
      {:event, %{key: @up}} ->
        nil

      {:event, %{key: @down}} ->
        nil

      _ ->
        model
    end
  end

  def render(model) do
    # server = Core.get_server(model.input)
    Logger.info(Blackjack.Core.Servers.server_players())
    {:ok, {_, _, server}} = model.data
    Logger.info(inspect(server))

    %{
      "server_name" => server_name,
      "player_count" => player_count,
      "table_count" => table_count
    } = server |> Jason.decode!()

    view do
      panel title: "BLACKJACK" do
        row do
          column size: 4 do
            panel title: "Tables" do
              label(content: "TABLES")
            end

            # label(content: server_name)
            # label(content: player_count)
            # label(content: table_count)
          end

          column size: 8 do
            panel title: "Table info" do
              label(content: "TABLE INFO")
            end
          end
        end
      end
    end
  end
end
