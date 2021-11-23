defmodule BlackjackCLI.Views.CreateServer.State do
  require Logger

  import Ratatouille.Constants, only: [key: 1]

  @space_bar key(:space)
  @tab key(:tab)
  @enter key(:enter)

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]

  def update(model, msg) do
    case msg do
      {:event, %{key: key}} when key in @delete_keys ->
        %{model | input: String.slice(model.input, 0..-2)}

      {:event, %{key: @space_bar}} ->
        %{model | input: model.input <> " "}

      {:event, %{ch: ch}} when ch > 0 ->
        %{model | input: model.input <> <<ch::utf8>>}

      {:event, %{key: @enter}} ->
        case :httpc.request(
               :post,
               {'http://localhost:#{Application.get_env(:blackjack, :port)}/server/create', [],
                'application/json',
                Jason.encode!(%{server_name: model.input, username: model.user.username})},
               [],
               []
             ) do
          {:ok, {_status, _meta, _server}} ->
            {:ok, {_status, _meta, list_servers}} =
              :httpc.request("http://localhost:#{Application.get_env(:blackjack, :port)}/servers")

            list_servers = Jason.decode!(list_servers)

            %{model | input: 0, screen: :servers, data: list_servers}

          {:error, _server} ->
            %{model | input: model.input, screen: :create_server}
        end

      _ ->
        model
    end
  end
end
