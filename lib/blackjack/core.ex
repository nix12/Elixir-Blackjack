defmodule Blackjack.Core do
  require Logger

  alias Blackjack.Core.{Servers, Supervisor}

  # Server

  # def create_server(server_name, username) do
  #   # Supervisor.start_child({:create, server_name, username})
  #   # |> then(fn _server -> get_server(server_name) end)
  # end

  # def start_server(server) do
  #   #
  # end

  def get_server(server_name) do
    Servers.get_server(server_name)
  end

  # def sync_server(server) do
  #   Servers.update_server(server)
  # end

  def add_user_to_server(server_name, username) do
    Servers.add_user(server_name, username)
  end

  def remove_user_from_server(server_name, username) do
    Servers.remove_user(server_name, username)
  end
end
