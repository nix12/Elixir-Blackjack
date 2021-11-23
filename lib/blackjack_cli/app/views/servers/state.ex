defmodule BlackjackCLI.Views.Servers.State do
  require Logger

  import Ratatouille.Constants, only: [key: 1]

  alias Ratatouille.Runtime.Command
  alias BlackjackCLI.Controllers.AccountsController

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)
  @tab key(:tab)

  @spec update(any, any) :: any
  def update(model, msg) do
    case msg do
      {:event, %{key: @tab}} ->
        switch_menus(model)

      {:event, %{ch: ?w}} ->
        update_cmd(%{model | input: max(model.input - 1, 0), data: model.data})

      {:event, %{key: @down}} ->
        if model.menu == true do
          %{model | input: min(model.input + 1, length(menu()) - 1), data: model.data}
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
          %{"server_name" => server_name} = match_servers(model.data, model.input)

          BlackjackCLI.join_server(model)
          BlackjackCLI.subscribe_server(model)
          %{model | screen: :server, data: BlackjackCLI.get_server(server_name)}
        else
          case match_menu(model) do
            :menu ->
              %{model | screen: match_menu(model), input: 0}

            _ ->
              %{model | screen: match_menu(model), input: ""}
          end
        end

      _ ->
        model
    end
  end

  defp menu do
    [:create_server, :find_server, :menu]
  end

  defp match_menu(model) do
    menu()
    |> Enum.at(model.input)
  end

  defp match_servers(servers, index) do
    servers
    |> Enum.find(fn server ->
      servers |> Enum.at(index) == server
    end)
  end

  defp update_cmd(model) do
    list_servers =
      if Enum.count(model.data) > 0 and model.menu == false do
        {:ok, {_, _, list_servers}} =
          :httpc.request('http://localhost:#{Application.get_env(:blackjack, :port)}/servers')

        list_servers |> Jason.decode!()
      else
        []
      end

    Command.new(fn -> list_servers end, :servers_updated)

    model
  end

  def switch_menus(model) do
    %{model | menu: !model.menu}
  end
end
