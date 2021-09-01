defmodule BlackjackCLI.Views.Start.State do
  import Ratatouille.Constants, only: [key: 1]

  @up key(:arrow_up)
  @down key(:arrow_down)
  @enter key(:enter)
  @doc """
   Updates the model state based upon keypress and
   menu selection
  """
  @spec update(map(), tuple()) :: map()
  def update(model, msg) do
    case msg do
      {:event, %{ch: ?w}} ->
        %{model | input: model.input - 1}

      {:event, %{key: @up}} ->
        %{model | input: model.input - 1}

      {:event, %{ch: ?s}} ->
        %{model | input: model.input + 1}

      {:event, %{key: @down}} ->
        %{model | input: model.input + 1}

      {:event, %{key: @enter}} ->
        case match_screen(model.input) do
          :login ->
            BlackjackCLI.Views.Login.State.start_login()

          :registration ->
            BlackjackCLI.Views.Registration.State.start_registration()
            BlackjackCLI.Views.Login.State.start_login()

          :exit ->
            :exit
        end

        %{model | screen: match_screen(model.input)}

      _ ->
        model
    end
  end

  @spec screens() :: tuple()
  defp screens do
    {:login, :registration, :exit}
  end

  @spec match_screen(integer()) :: atom()
  defp match_screen(index) do
    Enum.find(screens() |> Tuple.to_list(), &(screens() |> elem(index) == &1))
  end
end
