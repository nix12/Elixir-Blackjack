defmodule BlackjackWeb.Controllers.ServersController do
  @moduledoc """
    Contains CRUD actions for servers.
  """
  require Logger

  import Plug.Conn

  alias Blackjack.Repo
  alias Blackjack.Core.Supervisor, as: CoreSupervisor
  alias Blackjack.Core.{Server, ServerQuery}
  alias Blackjack.Notifiers.AccountsNotifier
  alias Blackjack.Accounts.Authentication.Guardian

  def index(conn) do
    case Repo.all(Server) do
      [] ->
        assign(conn, :servers, [])

      servers ->
        assign(conn, :servers, servers)
    end
  end

  def create(conn) do
    user = Guardian.Plug.current_resource(conn)
    %{"server" => %{"server_name" => server_name}} = conn.params

    changeset =
      Server.changeset(%Server{}, %{
        server_name: server_name,
        user_id: user.id |> Ecto.UUID.cast!()
      })

    case changeset |> Repo.insert() do
      {:ok, server} ->
        AccountsNotifier.publish(
          user |> Map.put("mod", CoreSupervisor),
          {:start_server, server}
        )

        {:ok, assign(conn, :server, server)}

      {:error, error} ->
        {:errors, assign(conn, :errors, error)}
    end
  end

  def update do
  end

  def show(%{params: %{"server_name" => server_name}} = conn) do
    case server_name |> ServerQuery.query_server() |> Repo.one() do
      nil ->
        {:error, assign(conn, :errors, "No server found.")}

      server ->
        {:ok, assign(conn, :server, server)}
    end
  end

  def destroy do
  end

  # def join_server(%{params: %{"server_name" => server_name, "username" => username}}) do
  #   Accounts.join_server(username, server_name)
  # end

  # def leave_server(%{params: %{"server_name" => server_name, "username" => username}}) do
  #   Accounts.leave_server(username, server_name)
  # end
end
