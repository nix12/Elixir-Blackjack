defmodule BlackjackCLI.Views.Menu do
  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)

  def update(model, msg) do
    case msg do
      {:event, %{ch: ?w}} ->
        %{model | input: model.input - 1}

      {:event, %{key: @down}} ->
        %{model | input: model.input + 1}

      {:event, %{ch: ?s}} ->
        %{model | input: model.input + 1}

      {:event, %{key: @up}} ->
        %{model | input: model.input - 1}

      {:event, %{key: @enter}} ->
        %{model | screen: match_screen(model.input)}

      _ ->
        model
    end
  end

  def render(model) do
    view do
      panel title: "BLACKJACK" do
        if model.input == 0 do
          label(content: "1) Servers", background: :white, color: :black)
        else
          label(content: "1) Servers")
        end

        if model.input == 1 do
          label(content: "2) Search", background: :white, color: :black)
        else
          label(content: "2) Search")
        end

        if model.input == 2 do
          label(content: "3) Account", background: :white, color: :black)
        else
          label(content: "3) Account")
        end

        if model.input == 3 do
          label(content: "4) Settings", background: :white, color: :black)
        else
          label(content: "4) Settings")
        end

        if model.input == 4 do
          label(content: "5) Exit", background: :white, color: :black)
        else
          label(content: "5) Exit")
        end
      end
    end
  end

  defp screens do
    {:servers, :search, :account, :settings, :exit}
  end

  defp match_screen(index) do
    Enum.find(screens |> Tuple.to_list(), fn screen ->
      screens |> elem(index) == screen
    end)
  end
end
