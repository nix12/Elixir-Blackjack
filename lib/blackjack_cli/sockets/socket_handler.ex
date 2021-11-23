# defmodule BlackjackCLI.Sockets.SocketHandler do
#   @behaviour :cowboy_websocket

#   def init(request, _state) do
#     state = %{registry_key: request.path}

#     {:cowboy_websocket, request, state, %{idle_timeout: 300_000}}
#   end

#   def websocket_init(state) do
#     PubSub.subscribe(self(), state.registry_key)

#     {:ok, state}
#   end

#   def websocket_handle({:text, json}, state) do
#     payload = Jason.decode!(json)
#     message = payload["data"]["user"]["message"]

#     PubSub.publish(state.registry_key, message)

#     {:reply, {:text, message}, state}
#   end

#   def websocket_info(msg, state) do
#     {:reply, {:text, msg}, state}
#   end
# end
