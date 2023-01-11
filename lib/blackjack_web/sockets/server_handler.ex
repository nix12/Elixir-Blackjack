defmodule BlackjackWeb.Sockets.ServerHandler do
  @moduledoc """
    Handles websockets connections for servers.
  """
  require Logger

  @behaviour :cowboy_websocket

  alias Blackjack.Repo
  alias Blackjack.Accounts.Authentication.Guardian
  alias Blackjack.Accounts.{User, AccountsRegistry}
  alias Blackjack.Notifiers.CoreNotifier
  alias Blackjack.Core.ServerManager

  def init(request, _state) do
    Logger.info("WEBSOCKET REQUEST: #{inspect(request)}")
    "Bearer " <> token = request.headers["authorization"]
    {:ok, %{"user" => user} = claims} = Guardian.decode_and_verify(token)

    Logger.info("USER: #{inspect(claims)}")
    state = %{registry_key: request.path, current_user: user}

    {:cowboy_websocket, request, state, %{idle_timeout: :timer.minutes(5)}}
  end

  def websocket_init(%{registry_key: registry_key, current_user: %{"id" => id}} = state) do
    Logger.info("WEBSOCKET INIT: #{inspect(state)}")
    {:ok, _socket_pid} = Registry.register(Registry.Sockets, registry_key, %{})
    [{user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, id) |> IO.inspect(label: "HORDE")

    Process.monitor(user_pid)
    IO.puts("1")
    send(self(), {:connect})
    IO.puts("2")
    {[], state, :hibernate}
  end

  def websocket_handle({:text, json}, %{current_user: current_user} = state) do
    Logger.info("INCOMING: #{inspect(json)}")

    %{"action" => action, "payload" => data} = json |> Jason.decode!() |> IO.inspect()

    Logger.info("WEBSOCKET HANDLE: #{inspect(json)} -> #{inspect(state)}")

    server_name = data["server_name"]

    case action do
      "join_server" ->
        send(self(), {:join_server, server_name, current_user})

      "leave_server" ->
        send(self(), {:leave_server, server_name, current_user})
    end

    {[], state, :hibernate}
  end

  # def websocket_handle({:close, json}, state) do
  #   json = Jason.decode!(json)
  #   Logger.info("CLOSE WEBSOCKET HANDLE: #{inspect(json)} -> #{inspect(state)}")

  #   {:noreply, state}
  # end

  def websocket_info({:join_server, server_name, user}, state) do
    Logger.info("WEBSOCKET INFO: JOIN SERVER -> SELF(#{inspect(self())})")
    CoreNotifier.publish(server_name, {:join_server, server_name, user})

    joined_server = ServerManager.get_server(server_name)

    player_count =
      update_in(joined_server.server.player_count, fn _ ->
        Registry.lookup(Registry.Sockets, state.registry_key) |> Enum.count()
      end)

    Registry.dispatch(Registry.Sockets, state.registry_key, fn entries ->
      Logger.info("ENTRIES: #{inspect(entries)}")

      for {pid, _} <- entries do
        if pid != self() do
          send(pid, {:sync_server, player_count.server})
        end
      end
    end)

    Logger.info("CONNECTED: #{inspect(Registry.lookup(Registry.Sockets, state.registry_key))}")
    Logger.info("SEND PAYLOAD: #{inspect(player_count)}")

    payload = %{payload: %{server: player_count.server}} |> Jason.encode!()

    {[text: payload], state}
  end

  def websocket_info({:leave_server, server_name, user}, state) do
    Logger.info("WEBSOCKET INFO: LEAVE SERVER -> SELF(#{inspect(self())})")
    :ok = Registry.unregister(Registry.Sockets, state.registry_key)
    CoreNotifier.publish(server_name, {:leave_server, server_name, user})
    joined_server = ServerManager.get_server(server_name)

    player_count =
      update_in(joined_server.server.player_count, fn _ ->
        Registry.lookup(Registry.Sockets, state.registry_key) |> Enum.count()
      end)

    Registry.dispatch(Registry.Sockets, state.registry_key, fn entries ->
      Logger.info("ENTRIES: #{inspect(entries)}")

      for {pid, _} <- entries do
        if pid != self() do
          send(pid, {:sync_server, player_count.server})
        end
      end
    end)

    Logger.info("DISCONNECTED: #{inspect(Registry.lookup(Registry.Sockets, state.registry_key))}")
    Logger.info("SEND PAYLOAD: #{inspect(player_count)}")

    payload = %{payload: %{server: player_count.server}} |> Jason.encode!()

    message =
      %{message: "#{state.current_user["username"]} has left #{server_name}"}
      |> Jason.encode!()

    message |> IO.inspect(label: "PAYLOAD") |> byte_size() |> IO.inspect(label: "PAYLOAD SIZE")
    {[text: payload, close: message], state}
  end

  def websocket_info({:connect}, state) do
    IO.puts("3")
    message = %{message: "CONNECTED"} |> Jason.encode!()
    {[text: message], state}
  end

  def websocket_info({:sync_server, server}, state) do
    payload = %{payload: %{server: server}} |> Jason.encode!()
    IO.puts("SYNCING SERVER")
    {[text: payload], state}
  end

  def websocket_info({:message, message}, state) do
    message = %{message: message} |> Jason.encode!()
    Logger.info("MESSAGE SENT")
    {[text: message], state}
  end

  def websocket_info({:DOWN, _ref, :process, _object, _reason}, state) do
    Process.exit(self(), :kill)
    {:ok, state}
  end
end
