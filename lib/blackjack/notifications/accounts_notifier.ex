# Handles server instructionis
defmodule Blackjack.Notifications.AccountsNotifier do
  use GenServer

  alias Blackjack.Accounts.AccountsRegistry

  def start_link(_ \\ []) do
    GenServer.start_link(__MODULE__, :ok,
      name: Blackjack.via_horde({AccountsRegistry, __MODULE__})
    )
  end

  def publish(user, user_instruction) do
    GenServer.cast(
      Blackjack.via_horde({AccountsRegistry, __MODULE__}),
      {:notify_user, user, user_instruction}
    )
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_cast({:notify_user, user, user_instruction}, accounts) do
    {action, args} = decode_instruction(user_instruction)

    user
    |> then(& &1.mod)
    |> apply(action, [args])

    {:noreply, accounts}
  end

  defp decode_instruction({:start_server, server}), do: {:start_server, server}
  defp decode_instruction({:start_user, user}), do: {:start_user, user}
  defp decode_instruction({:update_user, user}), do: {:update_user, user}
end
