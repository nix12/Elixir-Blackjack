defmodule BlackjackCLI.Views.Server.State do
  require Logger

  import Ratatouille.Constants, only: [key: 1]

  alias Ratatouille.Runtime.Command

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)
  @tab key(:tab)

  def update(model, msg) do
    case msg do
      {:event, :subscribe_server} ->
        %{data: [%{"server_name" => server_name}] = data} = model
        response = Swarm.multi_call(server_name, {:sync_server, data})
        collapsed_response = response |> Enum.uniq()

        if Node.list() |> Enum.empty?() do
          %{model | data: collapsed_response}
        else
          [ok: new_model] =
            :erpc.multicall(Node.list(), fn ->
              BlackjackCLI.App.update(
                %{model | data: collapsed_response},
                :none
              )
            end)

          new_model
        end

      {:event, %{key: @tab}} ->
        switch_menus(model)

      {:event, %{ch: ?w}} ->
        update_cmd(%{model | input: max(model.input - 1, 0), data: model.data})

      {:event, %{key: @down}} ->
        if model.menu == true do
          %{model | input: min(model.input + 1, length(menu()) - 1)}
        else
          update_cmd(%{
            model
            | input: min(model.input + 1, length(model.data) - 1)
          })
        end

      {:event, %{ch: ?s}} ->
        update_cmd(%{
          model
          | input: min(model.input + 1, length(model.data) - 1)
        })

      {:event, %{key: @up}} ->
        if model.menu == true do
          %{model | input: max(model.input - 1, 0)}
        else
          update_cmd(%{model | input: max(model.input - 1, 0), data: model.data})
        end

      {:event, %{key: @enter}} ->
        if model.menu == false do
          # FETCH LIST OF TABLES
          # JOIN TABLE HERE

          %{model | screen: :server, data: []}
        else
          Logger.info("MODEL DATA: #{inspect(model.data)}")
          [%{"server_name" => server_name}] = model.data

          case match_menu(model) do
            :reload ->
              %{
                model
                | data: BlackjackCLI.get_server(server_name)
              }

            :servers ->
              :httpc.request(
                :post,
                {'http://localhost:#{Application.get_env(:blackjack, :port)}/server/#{server_name |> Blackjack.format_name()}/leave',
                 [], 'application/json',
                 Jason.encode!(%{server_name: server_name, username: model.user.username})},
                [],
                []
              )

              %{model | screen: match_menu(model), input: 0, data: fetch_servers()}

            _ ->
              %{model | screen: match_menu(model), input: ""}
          end
        end

      _ ->
        model
    end
  end

  defp menu do
    [:reload, :create_table, :find_table, :servers]
  end

  defp match_menu(model) do
    menu()
    |> Enum.at(model.input)
  end

  defp update_cmd(model) do
    # Setup to list tables
    list_servers =
      if Enum.count(model.data) > 0 and model.menu == false do
        {:ok, {_, _, list_servers}} = BlackjackCLI.get_servers()
        list_servers |> Jason.decode!()
      else
        []
      end

    Command.new(fn -> list_servers end, :servers_updated)

    model
  end

  defp switch_menus(model) do
    %{model | menu: !model.menu}
  end

  defp fetch_servers() do
    {:ok, {_, _, list_servers}} =
      :httpc.request("http://localhost:#{Application.get_env(:blackjack, :port)}/servers")

    Jason.decode!(list_servers) |> tap(&Logger.info/1)
  end
end
