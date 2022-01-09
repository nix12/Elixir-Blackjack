defmodule BlackjackCLI.App.State do
  @moduledoc """
    Main state for frontend application
  """
  require Logger

  alias BlackjackCLI.Views.{
    Start,
    Login,
    Registration,
    Account,
    Server,
    Servers,
    CreateServer,
    Games,
    Search,
    Dashboard,
    Menu
  }

  @initial_state %{
    input: 0,
    menu: true,
    user: nil,
    screen: :start,
    token: nil,
    data: []
  }

  @spec init() :: map()
  def init() do
    Process.register(self(), :gui)
    put_in(@initial_state.data, BlackjackCLI.get_servers())
  end

  # @spec update(map(), tuple()) :: map()
  def update(model, msg) do
    case {model, msg} do
      {%{token: nil}, :check_token} ->
        check_token(model)

      {%{screen: :login} = model, _} ->
        Login.State.update(model, msg)

      {%{screen: :registration} = model, _} ->
        Registration.State.update(model, msg)

      {%{screen: :account} = model, _} ->
        Account.update(model, msg)

      {%{screen: :server} = model, msg} ->
        Server.State.update(model, msg)

      {%{screen: :servers} = model, _} ->
        Servers.State.update(model, msg)

      {%{screen: :create_server} = model, _} ->
        CreateServer.update(model, msg)

      {%{screen: :games} = model, _} ->
        Games.update(model, msg)

      {%{screen: :search} = model, _} ->
        Search.update(model, msg)

      {%{screen: :dashboard} = model, _} ->
        Dashboard.update(model, msg)

      {%{screen: :menu} = model, _} ->
        Menu.State.update(model, msg)

      {%{token: nil} = model, _} ->
        Start.State.update(model, msg)

      _ ->
        model
    end
  end

  defp check_token(model) do
    case model.token do
      token when is_nil(token) == false or token != "" ->
        model

      _ ->
        BlackjackCLI.Views.Login.State.start_login()
        put_in(model.screen, :login)
    end
  end
end
