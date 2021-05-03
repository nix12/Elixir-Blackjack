defmodule Blackjack do
  alias Blackjack.Authentication.Guardian
  alias BlackjackWeb.Controllers.{RegistrationsController, AuthenticationController}

  @blackjack_node :blackjack@Developer

  # Development Commands

  # Blackjack.Supervisor.start_link()
  # Blackjack.create_users()
  # Blackjack.initialize_table()
  # Blackjack.Core.Dealers.deal_all("high rollers")

  def create_users do
    Blackjack.Accounts.Server.create_user("mastersd")
    Blackjack.Accounts.Server.create_user("test")
    Blackjack.Accounts.Server.create_user("user")
    Blackjack.Accounts.Server.create_user("tyrion")
  end

  def initialize_table do
    Blackjack.Core.Supervisor.create_server("ballers")
    Blackjack.Core.Server.create_table("ballers", "high rollers")
    Blackjack.Core.Tables.generate_dealer("high rollers")
  end

  def build do
    Blackjack.Core.Dealers.build_deck("high rollers")
  end

  def deal_hands do
    Blackjack.Core.Dealers.initialize_hands("high rollers")
  end

  ###### END ######

  # def start(_type, _args) do
  #   IO.puts("Starting Blackjack application.")

  #   case Blackjack.Supervisor.start_link() do
  #     {:ok, _pid} ->
  #       {:ok, nid} = Node.start(@blackjack_node, :shortnames)
  #       IO.inspect(Node.self(), label: "NODE NAME 2")

  #       {:ok, nid}

  #     {:error, {:shutdown, _term}} ->
  #       token = AuthenticationController.get_token()

  #       {:ok, %{"sub" => sub}} = Guardian.decode_and_verify(token)
  #       %{"user" => %{"username" => username}} = Jason.decode!(sub)

  #       if IO.inspect(!blank?(username), label: "BLANK?") do
  #         {:ok, nid} = Node.start("#{username}_node" |> String.to_atom(), :shortnames)
  #         Node.connect(@blackjack_node)
  #         IO.inspect(Node.self(), label: "NODE NAME 1")
  #         AuthenticationController.login(%Plug.Conn{}, username)
  #         {:ok, nid}
  #       else
  #         RegistrationsController.register()
  #       end
  #   end
  # end

  # {:ok,
  #  %{
  #    "aud" => "blackjack",
  #    "exp" => 1_621_643_683,
  #    "iat" => 1_619_051_683,
  #    "iss" => "blackjack",
  #    "jti" => "0c5f3653-ee40-4084-9a71-68a522d455bb",
  #    "nbf" => 1_619_051_682,
  #    "sub" => "{\"user\":{\"username\":\"\"}}",
  #    "typ" => "access"
  #  }}

  # Utilities

  def via_tuple(registry, name) do
    {:via, Registry, {registry, name}}
  end

  def format_name(name) do
    name
    |> String.trim()
    |> String.replace(" ", "_")
    |> String.to_atom()
  end

  def lookup(registry, name) do
    [{pid, _}] = Registry.lookup(registry, name)
    pid
  end

  def name(registry, pid) do
    Registry.keys(registry, pid) |> Enum.at(0)
  end

  def blank?(str_or_nil) do
    case str_or_nil |> to_string() |> String.trim() do
      "" -> true
      nil -> true
      _ -> false
    end
  end
end
