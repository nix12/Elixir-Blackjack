defmodule BlackjackCli.App do
  @behaviour Ratatouille.App

  require Logger

  alias Ratatouille.Runtime.Subscription
  alias BlackjackCli.App.State

  alias BlackjackCli.Views.{
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
  # def subscribe(%{token: nil}), do: Subscription.interval(50, :check_token)
  def subscribe(_), do: Subscription.interval(100_000, :check_token)

  @impl true
  def render(%{screen: :login, token: ""} = model), do: Login.render(model)

  def render(%{screen: :create_server, token: _, input: _} = model)
      when is_bitstring(model.input),
      do: CreateServer.render(model)

  def render(%{screen: :menu} = model) when is_integer(model.input),
    do: Menu.render(model)

  def render(%{screen: :login} = model), do: Login.render(model)
  def render(%{screen: :registration} = model), do: Registration.render(model)
  def render(%{screen: :servers} = model), do: Servers.render(model)
  def render(%{screen: :server} = model), do: Server.render(model)
  def render(%{screen: :create_server} = model), do: CreateServer.render(model)
  def render(%{screen: :games} = model), do: Games.render(model)
  def render(%{screen: :account} = model), do: Account.render(model)
  def render(%{screen: :search} = model), do: Search.render(model)
  def render(%{screen: :dashboard} = model), do: Dashboard.render(model)
  def render(%{screen: :settings} = model), do: Settings.render(model)
  def render(%{screen: :start} = model), do: Start.render(model)
  def render(%{screen: :exit}), do: Application.stop(:blackjack)
end
