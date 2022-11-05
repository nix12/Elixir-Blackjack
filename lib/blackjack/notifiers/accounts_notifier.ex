defmodule Blackjack.Notifiers.AccountsNotifier do
  @moduledoc """
    Handles and directs messages for User Accounts.
  """
  use GenServer

  alias Blackjack.Accounts.{User, AccountsRegistry}

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def publish(user, user_instruction) do
    GenServer.cast(__MODULE__, {:notify_user, user, user_instruction})
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_cast({:notify_user, %User{uuid: uuid}, user_instruction}, accounts) do
    {action, args} = decode_instruction(user_instruction)
    events = [args | []]
    [{user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, uuid)

    send(user_pid, {action, events})
    {:noreply, accounts}
  end

  defp decode_instruction({:update_user, user}), do: {:update_user, user}
  defp decode_instruction({:stop_user, empty}), do: {:stop_user, empty}

  defp decode_instruction({:create_friendship, requested_user}),
    do: {:create_friendship, requested_user}

  defp decode_instruction({:accept_friendship, requested_user}),
    do: {:accept_friendship, requested_user}

  defp decode_instruction({:decline_friendship, requested_user}),
    do: {:decline_friendship, requested_user}

  defp decode_instruction({:remove_friendship, requested_user}),
    do: {:remove_friendship, requested_user}

  defp decode_instruction({:start_server, server}), do: {:start_server, server}
end
