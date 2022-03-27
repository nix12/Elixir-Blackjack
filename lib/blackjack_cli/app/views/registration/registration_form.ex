defmodule BlackjackCli.Views.Registration.RegistrationForm do
  @moduledoc """
    Holds state for the registration view.
  """
  require Logger
  use GenServer

  @registry Registry.App

  @doc """
    Start registration form process
  """
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: Blackjack.via_tuple(@registry, :registration))
  end

  @doc """
    Retrieves values based on field
  """
  @spec get_field(atom()) :: list() | binary() | integer()
  def get_field(field) do
    GenServer.call(Blackjack.via_tuple(@registry, :registration), {:get_field, field})
  end

  @doc """
    Retrieve all fields
  """
  @spec get_fields :: map()
  def get_fields() do
    GenServer.call(Blackjack.via_tuple(@registry, :registration), {:get_fields})
  end

  @doc """
    Update a single field
  """
  @spec update_field(atom(), integer() | binary()) :: map()
  def update_field(field, input) do
    if field == :errors do
      IO.inspect(input, label: "============> FORM ERRORS")
    end

    GenServer.call(Blackjack.via_tuple(@registry, :registration), {:update_field, field, input})
  end

  @doc """
    Close the form process
  """
  @spec close_form :: :ok
  def close_form do
    GenServer.stop(Blackjack.via_tuple(@registry, :registration), :normal)
  end

  @doc """
    Initialize form process
  """
  @spec init(any) ::
          {:ok,
           %{
             errors: <<>>,
             password: <<>>,
             password_confirmation: <<>>,
             tab_count: 0,
             username: <<>>
           }}
  @impl true
  def init(_) do
    {:ok,
     %{
       tab_count: 0,
       username: "",
       password: "",
       password_confirmation: "",
       errors: ""
     }}
  end

  @impl true
  def handle_call({:get_field, field}, _from, registration_form) do
    {:reply, registration_form[field], registration_form}
  end

  def handle_call({:get_fields}, _from, registration_form) do
    {:reply, registration_form, registration_form}
  end

  def handle_call({:update_field, field, input}, _from, registration_form) do
    updated_registration_form =
      Map.update!(registration_form, field, fn value ->
        case field do
          :tab_count ->
            input

          _ ->
            if input == "" do
              String.replace_prefix(value, value, "")
            else
              value <> input
            end
        end
      end)

    {:reply, updated_registration_form, updated_registration_form}
  end
end
