defmodule Blackjack.Accounts.Users do
  use GenServer

  alias Blackjack.Accounts.User

  @registry Registry.Accounts

  # Client

  def start_link(%{user: %User{uuid: uuid}} = user) do
    GenServer.start_link(__MODULE__, user, name: Blackjack.via_tuple(@registry, uuid))
  end

  def get_user(uuid) do
    GenServer.call(Blackjack.lookup(@registry, uuid), {:get_user, uuid})
  end

  # Server

  @impl true
  def init(user) do
    {:ok, user}
  end

  @impl true
  def handle_call({:get_user, _uuid}, _from, user) do
    {:reply, user, user}
  end
end
