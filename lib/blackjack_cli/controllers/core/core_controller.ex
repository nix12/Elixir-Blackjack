defmodule BlackjackCLI.Controllers.CoreController do
  require Logger

  alias Blackjack.Repo
  alias Blackjack.Core
  alias Blackjack.Core.Server

  # @registry Registry.Web

  def get_servers(_conn) do
    Repo.all(Server)
    |> Enum.map(& &1)
    |> Jason.encode!()
  end

  # has been moved to Blackjack.Core.Servers.init/1
  def create_server(server_name) do
    Core.create_server(server_name)
  end

  # def remove_server(server_name) do
  #   Blackjack.lookup(@registry, __MODULE__)
  #   |> DynamicSupervisor.terminate_child(server_name)
  # end

  def get_server(%{params: %{"server_name" => server_name}}) do
    case Repo.get_by!(Server, server_name: server_name |> Blackjack.unformat_name()) do
      {:error, changeset} ->
        changeset

      server ->
        Logger.info("qwas #{inspect(server)}")

        server
        |> Map.from_struct()
        |> Map.drop([:__meta__])
        |> Jason.encode!()
    end
  end
end
