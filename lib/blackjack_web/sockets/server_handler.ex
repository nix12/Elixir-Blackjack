defmodule BlackjackWeb.Sockets.ServerHandler do
  require Logger

  @behaviour :cowboy_websocket

  alias Blackjack.Notifications.CoreNotifier
  alias Blackjack.Core.ServerManager

  def init(request, _state) do
    state = %{registry_key: request.path}

    {:cowboy_websocket, request, state, %{idle_timeout: 30000}}
  end

  def websocket_init(state) do
    Logger.info("WEBSOCKET INIT: #{inspect(state)}")
    send(self(), {:push, "PUSING MESSAGE"})
    {:ok, state}
  end

  def websocket_handle({:text, json}, state) do
    json = Jason.decode!(json)
    Logger.info("WEBSOCKET HANDLE: #{inspect(json)} -> #{inspect(state)}")

    CoreNotifier.publish(
      json |> Map.put(:mod, ServerManager),
      {:join_server, json.server_name, json.user}
    )

    {:reply, {:text, "FROM SERVER"}, state}
  end

  def websocket_handle({:ping, "ping"}, state) do
    {:reply, {:pong, "pong"}, state}
  end

  def websocket_info({:push, msg}, state) do
    Logger.info("WEBSOCKET INFO: #{inspect(msg)} -> #{inspect(state)}")
    {:reply, {:text, msg}, state}
  end
end
