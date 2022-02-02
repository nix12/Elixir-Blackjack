defmodule BlackjackCli.Controllers.ServersController do
  alias Blackjack.{Accounts, Core}

  # @registry Registry.App

  def index(_conn) do
    Core.get_servers()
  end

  def create(%{params: %{"server_name" => server_name, "username" => username}}) do
    Core.create_server(server_name, username)
  end

  # def remove_server(server_name) do
  #   Blackjack.lookup(@registry, __MODULE__)
  #   |> DynamicSupervisor.terminate_child(server_name)
  # end

  def show(%{params: %{"server_name" => server_name}}) do
    Core.get_server(server_name)
  end

  def join_server(%{params: %{"server_name" => server_name, "username" => username}}) do
    Accounts.join_server(username, server_name)
  end

  def leave_server(%{params: %{"server_name" => server_name, "username" => username}}) do
    Accounts.leave_server(username, server_name)
  end
end
