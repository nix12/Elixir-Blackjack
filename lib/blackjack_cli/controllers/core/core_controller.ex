defmodule BlackjackCLI.Controllers.CoreController do
  require Logger

  alias Blackjack.{Core, Repo}

  # @registry Registry.Web

  def get_servers(_conn) do
    Core.get_servers()
  end

  def create_server(%{params: %{"server_name" => server_name, "username" => username}}) do
    Core.create_server(server_name, username)
  end

  # def remove_server(server_name) do
  #   Blackjack.lookup(@registry, __MODULE__)
  #   |> DynamicSupervisor.terminate_child(server_name)
  # end

  def get_server(%{params: %{"server_name" => server_name}}) do
    Core.get_server(server_name |> Blackjack.unformat_name())
    |> Repo.preload(:user)
    |> Jason.encode!()
  end
end
