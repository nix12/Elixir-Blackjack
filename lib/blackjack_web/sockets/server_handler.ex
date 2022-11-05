defmodule BlackjackWeb.Sockets.ServerHandler do
  @moduledoc """
    Handles websockets connections for servers.
  """
  require Logger

  @behaviour :cowboy_websocket

  alias Blackjack.Repo
  alias Blackjack.Accounts.User
  alias Blackjack.Notifications.CoreNotifier
  alias Blackjack.Core.ServerManager

  def init(request, _state) do
    state = %{registry_key: request.path}

    {:cowboy_websocket, request, state, %{idle_timeout: :timer.minutes(10)}}
  end

  def websocket_init(state) do
    Logger.info("WEBSOCKET INIT: #{inspect(state)}")
    Registry.register(Registry.Sockets, state.registry_key, %{})

    send(self(), {:connect})
    {:ok, state}
  end

  def websocket_handle({:text, json}, state) do
    %{"action" => action, "payload" => data} = Jason.decode!(json)

    Logger.info("WEBSOCKET HANDLE: #{inspect(json)} -> #{inspect(state)}")

    server_name = data["server_name"]

    user =
      Repo.get!(User, data["user"]["uuid"])
      |> Map.put("mod", ServerManager)

    case action do
      "join_server" ->
        send(self(), {:join_server, server_name, user})

      "leave_server" ->
        send(self(), {:leave_server, server_name, user})
    end

    {:ok, state}
  end

  def websocket_handle({:close, json}, state) do
    json = Jason.decode!(json)
    Logger.info("WEBSOCKET HANDLE: #{inspect(json)} -> #{inspect(state)}")

    {:noreply, state}
  end

  def websocket_info({:join_server, server_name, user}, state) do
    Logger.info("WEBSOCKET INFO: JOIN SERVER -> SELF(#{inspect(self())})")

    CoreNotifier.publish(server_name, {:join_server, server_name, user})
    :timer.sleep(200)
    server = ServerManager.get_server(server_name).server

    Registry.dispatch(Registry.Sockets, state.registry_key, fn entries ->
      Logger.info("ENTRIES: #{inspect(entries)}")

      for {pid, _} <- entries do
        if pid != self() do
          send(pid, {:sync_server, server})
        end
      end
    end)

    Logger.info("CONNECTED: #{inspect(Registry.lookup(Registry.Sockets, state.registry_key))}")
    {:reply, {:text, Jason.encode!(%{payload: %{server: server}})}, state}
  end

  def websocket_info({:leave_server, server_name, user}, state) do
    Logger.info("WEBSOCKET INFO: LEAVE SERVER")

    CoreNotifier.publish(server_name, {:leave_server, server_name, user})
    :timer.sleep(200)
    server = ServerManager.get_server(server_name).server

    Registry.dispatch(Registry.Sockets, state.registry_key, fn entries ->
      Logger.info("ENTRIES: #{inspect(entries)}")

      for {pid, _} <- entries do
        if pid != self() do
          send(pid, {:sync_server, server})
        end
      end
    end)

    {:reply, {:text, Jason.encode!(%{payload: %{server: server}})}, state}
  end

  def websocket_info({:connect}, state) do
    {:reply, {:text, Jason.encode!(%{message: "CONNECTED"})}, state}
  end

  def websocket_info({:sync_server, server}, state) do
    IO.puts("SYNCING SERVER")
    {:reply, {:text, Jason.encode!(%{payload: %{server: server}})}, state}
  end
end
