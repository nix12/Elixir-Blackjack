defmodule BlackjackCLI.App.State do
  @moduledoc """
    Main state for frontend application
  """
  alias Blackjack.Authentication.Guardian

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
    Menu,
    Exit
  }

  @initial_state %{
    input: 0,
    user: %{
      username: ""
    },
    screen: :start,
    token: nil,
    data: nil
  }

  @spec init() :: map()
  def init() do
    put_in(@initial_state.data, :httpc.request('http://localhost:4000/servers'))
  end

  @spec update(map(), tuple()) :: map()
  def update(model, msg) do
    case {model, msg} do
      # {%{token: nil, user: %{username: nil}}, :check_token} ->
      #   check_token(model)

      {%{screen: :login} = model, _} ->
        Login.update(model, msg)

      {%{screen: :registration} = model, _} ->
        Registration.update(model, msg)

      {%{screen: :account} = model, _} ->
        Account.update(model, msg)

      {%{screen: :server} = model, _} ->
        Server.update(model, msg)

      {%{screen: :servers} = model, _} ->
        Servers.update(model, msg)

      {%{screen: :create_server} = model, _} ->
        CreateServer.update(model, msg)

      {%{screen: :games} = model, _} ->
        Games.update(model, msg)

      {%{screen: :search} = model, _} ->
        Search.update(model, msg)

      {%{screen: :dashboard} = model, _} ->
        Dashboard.update(model, msg)

      {%{screen: :menu} = model, _} ->
        Menu.update(model, msg)

      {%{token: nil} = model, _} ->
        Start.update(model, msg)

      {%{screen: :exit}, _} ->
        Exit.update(model, msg)

      {%{token: nil}, _} ->
        put_in(model.screen, :login)

      {%{token: nil}, _} ->
        put_in(model.screen, :registration)

      {%{token: "" <> token}, _} ->
        put_in(model.screen, :account)

      {%{token: "" <> token}, _} ->
        put_in(model.screen, :server)

      {%{token: "" <> token}, _} ->
        put_in(model.screen, :servers)

      {%{token: "" <> token}, _} ->
        put_in(model.screen, :create_server)

      {%{token: "" <> token}, _} ->
        put_in(model.screen, :games)

      {%{token: "" <> token}, _} ->
        put_in(model.screen, :search)

      {%{token: "" <> token}, _} ->
        put_in(model.screen, :dashboard)

      {%{token: "" <> token}, msg} ->
        put_in(model.screen, :menu)

      _ ->
        model
    end
  end

  defp check_token(model) do
    case Guardian.encode_and_sign(model.user) do
      {:ok, token, claim} ->
        put_in(model.token, token)

      _ ->
        model
    end
  end
end
