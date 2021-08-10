defmodule BlackjackCLI.App.State do
  @moduledoc """
    Main state for frontend application
  """
  require Logger
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
    Menu
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
    case :httpc.request('http://localhost:4000/servers') do
      {:ok, {_, _, list_servers}} ->
        list_servers = list_servers |> Jason.decode!()

        put_in(@initial_state.data, list_servers)

      {:error, reason} ->
        IO.inspect("ERROR")
        Logger.info("REASON: #{reason}")
    end

    # Logger.info("RESPONSE: #{inspect(:httpc.request('http://localhost:4000/servers'))}")
    # put_in(@initial_state.data, :httpc.request('http://localhost:4000/servers'))
    # put_in(@initial_state.data, "SOMETHING!")
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
        Application.stop(:blackjack)

      {%{token: nil}, _} ->
        put_in(model.screen, :login)

      {%{token: nil}, _} ->
        put_in(model.screen, :registration)

      {%{token: "" <> _token}, _} ->
        put_in(model.screen, :account)

      {%{token: "" <> _token}, _} ->
        put_in(model.screen, :server)

      {%{token: "" <> _token}, _} ->
        put_in(model.screen, :servers)

      {%{token: "" <> _token}, _} ->
        put_in(model.screen, :create_server)

      {%{token: "" <> _token}, _} ->
        put_in(model.screen, :games)

      {%{token: "" <> _token}, _} ->
        put_in(model.screen, :search)

      {%{token: "" <> _token}, _} ->
        put_in(model.screen, :dashboard)

      {%{token: "" <> _token}, msg} ->
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
