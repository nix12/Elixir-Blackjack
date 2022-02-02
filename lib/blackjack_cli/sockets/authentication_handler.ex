defmodule BlackjackCli.Sockets.AuthenticationHandler do
  @behaviour :cowboy_websocket

  alias BlackjackCli.Controllers.AuthenticationController

  def init(request, _state) do
    state = %{registry_key: request.path}

    {:cowboy_websocket, request, state, %{idle_timeout: 300_000}}
  end

  def websocket_init(state) do
    IO.inspect(Node.self(), label: "NODE")

    {:ok, state}
  end

  def websocket_handle({:text, json}, state) do
    IO.inspect(self(), label: "HANDLE SOCKET PID")
    # AuthenticationController.get_credentials()
    payload = Jason.decode!(json)
    login = payload["data"]
    {:reply, {:text, login}, state}
  end

  def websocket_info(msg, state) do
    IO.inspect(self(), label: "INFO SOCKET PID")
    {:reply, {:text, msg}, state}
  end
end
