defmodule Blackjack.Accounts.Server do
  require Logger

  use DynamicSupervisor

  alias Blackjack.Accounts.Users

  @registry Registry.Accounts

  def start_link(_ \\ []) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: Blackjack.via_tuple(@registry, __MODULE__))
  end

  @impl true
  def init(_) do
    Logger.info("Starting Accounts Server.")
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_user(username) do
    Logger.info("Creating user '#{username}'.")
    child_spec = {Users, username}

    DynamicSupervisor.start_child(supervisor(), child_spec)
  end

  def remove_user(username) do
    DynamicSupervisor.terminate_child(
      supervisor(),
      Blackjack.lookup(@registry, Blackjack.format_name(username))
    )
  end

  def children() do
    DynamicSupervisor.which_children(supervisor())
  end

  def count_children() do
    DynamicSupervisor.count_children(supervisor())
  end

  def supervisor do
    [{pid, _}] = Registry.lookup(@registry, __MODULE__)
    pid
  end
end
