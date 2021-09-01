defmodule BlackjackCLI.Views.Menu.State do
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

  defp screens do
    {:servers, :search, :account, :settings, :exit}
  end

  defp match_screen(index) do
    Enum.find(screens() |> Tuple.to_list(), &(screens() |> elem(index) == &1))
  end
end
