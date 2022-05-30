defmodule BlackjackWeb.Controllers.ServersController do
  import Plug.Conn

  alias Blackjack.{Accounts, Repo}
  alias Blackjack.Core.Supervisor, as: CoreSupervisor
  alias Blackjack.Core.{Server, ServerQuery}
  alias Blackjack.Notifications.AccountsNotifier

  def index(conn) do
    case Repo.all(Server) do
      [] ->
        assign(conn, :servers, [])

      servers ->
        assign(conn, :servers, servers)
    end
  end

  def create(conn) do
    IO.inspect(conn)
    uuid = conn.params["current_user"]["uuid"]
    old_user = Repo.get!(Blackjack.Accounts.User, uuid)
    server_name = conn.params["server"]["server_name"]

    update_user_with_server =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:server, Server.changeset(%Server{}, %{server_name: server_name}))
      |> Ecto.Multi.update(:user, fn %{server: server} ->
        old_user
        |> Repo.preload(:server)
        |> Ecto.Changeset.change(%{server: server})
      end)
      |> Repo.transaction()

    case update_user_with_server do
      {:ok, user} ->
        AccountsNotifier.publish(
          user |> Map.put(:mod, CoreSupervisor),
          {:start_server, user.server}
        )

        {:ok, assign(conn, :server, user.server)}

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

  def join_server(%{params: %{"server_name" => server_name, "username" => username}}) do
    Accounts.join_server(username, server_name)
  end

  def leave_server(%{params: %{"server_name" => server_name, "username" => username}}) do
    Accounts.leave_server(username, server_name)
  end
end
