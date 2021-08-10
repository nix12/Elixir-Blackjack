defmodule BlackjackCLI.App do
  @behaviour Ratatouille.App

  # alias Ratatouille.Runtime.Subscription
  alias BlackjackCLI.App.State

  alias BlackjackCLI.Views.{
    Start,
    Login,
    Registration,
    Server,
    Servers,
    CreateServer,
    Games,
    Account,
    Search,
    Dashboard,
    Menu,
    Settings
  }

  @impl true
  def init(_context), do: State.init()

  @impl true
  def update(model, msg), do: State.update(model, msg)

  @impl true
  def render(%{screen: :login, token: nil, input: _} = model) when is_bitstring(model.input),
    do: Login.render(model)

  def render(%{screen: :registration, token: nil, input: _} = model)
      when is_integer(model.input),
      do: Registration.render(model)

  def render(%{screen: :create_server, token: _, input: _} = model)
      when is_bitstring(model.input),
      do: CreateServer.render(model)

  def render(%{screen: :server, token: token} = model) when is_bitstring(model.input),
    do: Server.render(model)

  def render(%{screen: :menu, token: token, input: input} = model) when is_integer(model.input),
    do: Menu.render(model)

  def render(%{screen: :login, token: nil} = model), do: Login.render(model)
  def render(%{screen: :registration, token: nil} = model), do: Registration.render(model)
  def render(%{screen: :servers, token: token} = model), do: Servers.render(model)
  def render(%{screen: :create_server, token: token} = model), do: CreateServer.render(model)
  def render(%{screen: :games, token: token} = model), do: Games.render(model)
  def render(%{screen: :account, token: token} = model), do: Account.render(model)
  def render(%{screen: :search, token: token} = model), do: Search.render(model)
  def render(%{screen: :dashboard, token: token} = model), do: Dashboard.render(model)
  def render(%{screen: :settings, token: token} = model), do: Settings.render(model)
  def render(%{screen: :start} = model), do: Start.render(model)
  def render(%{screen: :exit} = model), do: Application.stop(:blackjack)

  # @impl true
  # def subscribe(%{token: nil}), do: Subscription.interval(500, :check_token)
  # def subscribe(_), do: Subscription.interval(100_000, :check_token)
end
