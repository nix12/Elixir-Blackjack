defmodule Blackjack.Notifications.CoreNotifier do
  # Handles server_name instructionis
  use GenServer

  alias Blackjack.Accounts.CoreRegistry

  def start_link(_ \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: Blackjack.via_horde({CoreRegistry, __MODULE__}))
  end

  def publish(server_name, server_instruction) do
    GenServer.cast(
      Blackjack.via_horde({CoreRegistry, __MODULE__}),
      {:notify_server, server_name, server_instruction}
    )
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_cast({:notify_server, server_name, server_instruction}, server) do
    {action, args} = decode_instruction(server_instruction)

    server_name
    |> then(& &1.mod)
    |> apply(action, [args])

    {:noreply, server}
  end

  defp decode_instruction({:join_server, server_name, user}),
    do: {:join_server, server_name, user}

  defp decode_instruction({:leave_server, server_name, user}),
    do: {:leave_server, server_name, user}

  defp decode_instruction({:update_user_count, server_name}),
    do: {:update_user_count, server_name}
end
