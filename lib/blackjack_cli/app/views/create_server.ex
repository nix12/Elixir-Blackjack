defmodule BlackjackCLI.Views.CreateServer do
  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCLI.Controllers.ServersController

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
        case ServersController.create_server(model.input) do
          {:ok, _server} ->
            %{model | input: 0, screen: :servers}

          {:error, _server} ->
            %{model | input: model.input, screen: :create_server}
        end

      _ ->
        model
    end
  end

  def render(model) do
    view do
      panel title: "BLACKJACK" do
        row do
          column size: 12 do
            panel title: "SERVER NAME" do
              label do
                text(content: model.input)
                text(content: "W", background: :white, color: :white)
              end
            end
          end
        end
      end
    end
  end
end
