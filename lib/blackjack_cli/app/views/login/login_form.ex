defmodule BlackjackCli.Views.Login.LoginForm do
  @moduledoc """
    Holds state for the login view.
  """

  use GenServer

  @registry Registry.App

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: Blackjack.via_tuple(@registry, :login))
  end

  def get_field(field) do
    GenServer.call(Blackjack.via_tuple(@registry, :login), {:get_field, field})
  end

  def get_fields() do
    GenServer.call(Blackjack.via_tuple(@registry, :login), {:get_fields})
  end

  def update_field(field, input) do
    GenServer.call(Blackjack.via_tuple(@registry, :login), {:update_field, field, input})
  end

  def close_form do
    GenServer.stop(Blackjack.via_tuple(@registry, :login), :normal)
  end

  @impl true
  def init(_) do
    {:ok, %{tab_count: 0, username: "", password: "", errors: ""}}
  end

  @impl true
  def handle_call({:get_field, field}, _from, login_form) do
    {:reply, login_form[field], login_form}
  end

  def handle_call({:get_fields}, _from, login_form) do
    {:reply, login_form, login_form}
  end

  def handle_call({:update_field, field, input}, _from, login_form) do
    updated_login_form =
      Map.update!(login_form, field, fn value ->
        case field do
          :tab_count ->
            input

          _ ->
            value <> input
        end
      end)

    {:reply, updated_login_form, updated_login_form}
  end
end
