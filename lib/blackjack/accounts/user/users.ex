defmodule Blackjack.Accounts.Users do
  use GenServer

  alias Blackjack.Repo
  alias Blackjack.Accounts.User

  @registry Registry.Accounts

  # Client

  def start_link(username) do
    GenServer.start(__MODULE__, username, name: Blackjack.via_tuple(@registry, username))
  end

  def get_user(username) do
    [{pid, _}] = Registry.lookup(@registry, username)

    GenServer.call(pid, {:get_user, username})
  end

  # Server

  @impl true
  def init(username) do
    IO.puts("Retrieving user.")
    user = Repo.get_by!(User, username: username)

    IO.puts("Populating user.")
    GenServer.cast(self(), {:populate_user})

    {:ok, {self(), user}}
  end

  @impl true
  def handle_cast({:populate_user}, user) do
    {:noreply, user}
  end

  @impl true
  def handle_call({:get_user, _username}, _from, state) do
    {:reply, state, state}
  end
end
