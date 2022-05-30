defmodule Blackjack.Accounts.UserManager do
  require Logger

  use GenServer

  alias Blackjack.Repo
  alias Blackjack.Core
  alias Blackjack.Accounts.{User, Users, AccountsRegistry}

  # Client

  @spec start_link(map()) :: {:ok, pid()} | no_return()
  def start_link(user_account) do
    case GenServer.start_link(__MODULE__, user_account,
           name: Blackjack.via_horde({AccountsRegistry, user_account.uuid})
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
  def get_user(uuid) do
    GenServer.call(Blackjack.via_horde({AccountsRegistry, uuid}), {:get_user})
  end

  def update_user(uuid, user) do
    GenServer.cast(Blackjack.via_horde({AccountsRegistry, uuid}), {:update_user, user})
  end

  # Server

  @impl true
  @spec init(map()) :: {:ok, map()}
  def init(user_account) do
    # Handle user crash
    # Process.flag(:trap_exit, true)

    {:ok, user_account}
  end

  @impl true
  def handle_call({:get_user}, _from, user_account) do
    {:reply, user_account, user_account}
  end

  @impl true
  def handle_cast({:update_user, user}, user_account) do
    changeset = User.changeset(%User{uuid: user_account.uuid}, user |> Map.delete(:mod))
    updated_user = Repo.update(changeset)

    {:noreply, updated_user}
  end

  # For updating all connected databases, but will be using single database
  # def handle_call({:sync_server, [server_data] = _server}, _from, user_account) do
  #   {:reply, Core.sync_server(server_data), user_account}
  # end
end
