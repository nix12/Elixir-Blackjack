defmodule Blackjack.Accounts.Users do
  use GenServer

  alias Blackjack.Repo
  alias Blackjack.Accounts.User

  @registry Registry.Accounts

  # Client

  def start_link(username) do
    GenServer.start(__MODULE__, username, name: Blackjack.via_tuple(@registry, username))
  end

  def get_user_by_username(username) do
    GenServer.call(Blackjack.lookup(@registry, username), {:get_user_by_username, username})
  end

  # Server

  @impl true
  def init(username) do
    IO.puts("Retrieving user.")
    user = Repo.get_by!(User, username: username)

    {:ok, {self(), user}}
  end

  @impl true
  def handle_call({:get_user_by_username, _username}, _from, user) do
    {:reply, user, user}
  end
end
