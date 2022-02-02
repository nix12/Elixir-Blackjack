# defmodule UserImpl do
#   @moduledoc """
#   An implementation of a UserImpl
#   """
#   require Logger

#   @behaviour UserBehaviour

#   @impl true
#   def get_user(user_params) when is_map(user_params) do
#     IO.inspect("GET USER IMPL CALLED")
#     # Here you could call an external api directly with an HTTP client or use a third
#     # party library that does that work for you. In this example we send a
#     # request using a `httpc` to get back some html, which we can process later.

#     :inets.start()
#     :ssl.start()

#     case :httpc.request(
#            :post,
#            {Blackjack.login_path(), [], 'application/json', Jason.encode!(user_params)},
#            [],
#            []
#          ) do
#       {:ok, {_, _meta, resource}} ->
#         Logger.debug(resource)
#         {:ok, Jason.decode(resource)} |> tap(&IO.inspect("IMPLEMENTATION: #{&1}"))

#       error ->
#         {:error, "Error getting user: #{inspect(error)}"}
#     end
#   end
# end
