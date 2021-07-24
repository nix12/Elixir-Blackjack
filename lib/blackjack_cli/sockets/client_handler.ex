defmodule BlackjackCLI.Sockets.ClientHandler do
  @behaviour :cowboy_websocket

  alias BlackjackCLI.Controllers.AuthenticationController

  def init(request, _state) do
    state = %{registry_key: request.path}
    IO.inspect(self(), label: "CLIENT INIT PID")

    {:cowboy_websocket, request, state, %{idle_timeout: 300_000}}
  end

  def websocket_init(state) do
    {:reply, {:text, "something"}, state}
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
