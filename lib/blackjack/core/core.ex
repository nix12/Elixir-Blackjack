defmodule Blackjack.Core do
  alias Blackjack.Repo
  alias Blackjack.Core.{Servers, Server, Supervisor}

  # Player

  # def create_player(player_name) do
  #   Accounts.get_user_by_username!(player_name)
  #   |> Players.start()
  # end

  # Server

  def get_servers do
    Repo.all(Server)
    |> Enum.map(& &1)
    |> Repo.preload(:user)
    |> Jason.encode!()
  end

  def create_server(server_name, username) do
    Supervisor.register({:create, server_name, username})
    |> then(fn _server -> get_server(server_name) end)
  end

  def get_server(server_name) do
    Servers.get_server(server_name)
  end

  def sync_server(server) do
    Servers.update_server(server)
  end

  def add_user_to_server(server_name, username) do
    Servers.add_user(server_name, username)
  end

  def remove_user_from_server(server_name, username) do
    Servers.remove_user(server_name, username)
  end
end
