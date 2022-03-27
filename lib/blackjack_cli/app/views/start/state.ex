defmodule BlackjackCli.Views.Start.State do
  import Ratatouille.Constants, only: [key: 1]

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)

  @type model() :: Map.t()
  @type event() :: {atom(), map()}

  @doc """
    Takes a model and an event to evaluate and update start view.
  """
  @spec update(map(), {:event, map()} | map()) :: map()
  def update(model, msg) do
    case msg do
      {:event, %{ch: ?w}} ->
        %{model | input: max(model.input - 1, 0)}

      {:event, %{key: @up}} ->
        %{model | input: max(model.input - 1, 0)}

      {:event, %{ch: ?s}} ->
        %{model | input: min(model.input + 1, length(screens()) - 1)}

      {:event, %{key: @down}} ->
        %{model | input: min(model.input + 1, length(screens()) - 1)}

      {:event, %{key: @enter}} ->
        case match_screen(model.input) do
          :login ->
            BlackjackCli.Views.Login.State.start_login()

          :registration ->
            BlackjackCli.Views.Registration.State.start_registration()

          :exit ->
            :exit
        end

        %{model | input: "", screen: match_screen(model.input), menu: false}

      _ ->
        model
    end
  end

  defp screens do
    [:login, :registration, :exit]
  end

  defp match_screen(index) do
    Enum.find(screens(), &(screens() |> Enum.at(index) == &1))
  end
end
