defmodule BlackjackWeb.Sockets.ClientHandler do
  @behaviour :cowboy_websocket

  alias BlackjackWeb.Controllers.AuthenticationController

  def init(request, _state) do
    state = %{registry_key: request.path}
    IO.inspect(self(), label: "CLIENT INIT PID")

    {:cowboy_websocket, request, state, %{idle_timeout: 300_000}}
  end

  def websocket_init(state) do
    conn = %Plug.Conn{}
    IO.inspect(self(), label: "INIT SOCKET PID")
    IO.inspect(conn, label: "CONN")

    IO.write(:player1@Developer, "Enter username:\n")

    username =
      IO.read(:stdio, :line)
      |> to_string()
      |> String.trim()

    {:reply, {:text, AuthenticationController.login(conn, username)}, state}
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
