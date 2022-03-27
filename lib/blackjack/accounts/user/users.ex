defmodule Blackjack.Accounts.Users do
  require Logger

  use GenServer

  import Ecto.Query, only: [from: 2]

  alias Blackjack.{Repo, Core}
  alias Blackjack.Accounts.AccountsRegistry

  # Client
  @spec start_link(map()) :: {:ok, pid()} | no_return()
  def start_link(user_account) do
    case GenServer.start_link(__MODULE__, user_account,
           name: Blackjack.via_horde({AccountsRegistry, user_account.username})
         ) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info(
          "#{user_account.username} is already started at #{inspect(pid)}, returning :ignore"
        )

        :ignore
    end
  end

  @spec get_user(binary()) :: map()
  def get_user(username) do
    GenServer.call(Blackjack.via_horde({AccountsRegistry, username}), {:get_user})
  end

  # Server

  @impl true
  @spec init(map()) :: {:ok, map()}
  def init(%{username: username}) do
    # Handle user crash
    # Process.flag(:trap_exit, true)

    user_account =
      case username |> query_users() |> Repo.one() do
        nil ->
          "No user found."

        user ->
          user
      end

    {:ok, user_account}
  end

  @impl true
  def handle_call({:get_user}, _from, user_account) do
    {:reply, user_account, user_account}
  end

  def handle_call({:sync_server, [server_data] = _server}, _from, user_account) do
    {:reply, Core.sync_server(server_data), user_account}
  end

  defp query_users(username) do
    from(
      u in "users",
      where: u.username == ^username,
      select: %{
        uuid: u.uuid,
        username: u.username,
        password_hash: u.password_hash,
        inserted_at: u.inserted_at,
        updated_at: u.updated_at
      }
    )
  end
end
