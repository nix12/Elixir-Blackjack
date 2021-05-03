defmodule Blackjack.Core do
  alias Blackjack.Accounts
  alias Blackjack.Core.{Players, Supervisor}

  # Player

  def create_player(player_name) do
    Accounts.get_user_by_username!(player_name)
    |> Players.start()
  end

  # Server

  def create_server(server_name) do
    Supervisor.create_server(server_name)
  end

  def list_servers do
    Supervisor.list_servers()
  end

  # Game
end
