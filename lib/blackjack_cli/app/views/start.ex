defmodule BlackjackCLI.Views.Start do
  @moduledoc """
    Shows the start menu for the blackjack application
  """
  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCLI.Views.{Login, Registration}

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
          :registration ->
            Registration.start_registration()

          :login ->
            :login

          :exit ->
            :exit
        end

        %{model | screen: match_screen(model.input)}

      _ ->
        model
    end
  end

  @doc """
    Renders start menu
  """
  def render(model) do
    view do
      panel title: "BLACKJACK" do
        if model.input == 0 do
          label(content: "1) Login", background: :white, color: :black)
        else
          label(content: "1) Login")
        end

        if model.input == 1 do
          label(content: "2) Register", background: :white, color: :black)
        else
          label(content: "2) Register")
        end

        if model.input == 2 do
          label(content: "3) Exit", background: :white, color: :black)
        else
          label(content: "3) Exit")
        end
      end
    end
  end

  @doc """
    List of possible srart menu selections
  """
  @spec screens() :: tuple()
  defp screens do
    {:login, :registration, :exit}
  end

  @doc """
    Matches screen based on index of screens()
  """
  @spec match_screen(integer()) :: atom()
  defp match_screen(index) do
    Enum.find(screens |> Tuple.to_list(), &(screens |> elem(index) == &1))
  end
end
