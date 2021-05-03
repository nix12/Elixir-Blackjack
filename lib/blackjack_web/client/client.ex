defmodule BlackjackWeb.Client do
  use GenServer

  alias Blackjack.Authentication.Guardian
  alias Blackjack.Core
  alias BlackjackWeb.Controllers.{AuthenticationController, RegistrationsController}

  @registry Registry.Client

  # Client

  def start_link(_) do
    GenServer.start_link(
      __MODULE__,
      :ok,
      name: Blackjack.via_tuple(@registry, __MODULE__)
    )
  end

  # Server

  def init(:ok) do
    case AuthenticationController.get_token() |> IO.inspect(label: "GET TOKEN") do
      {:ok, token} ->
        {:ok, %{"sub" => %{"username" => username}}} = Guardian.decode_and_verify(token)

        follow_login(username)

      {:error, token} ->
        IO.puts("NO TOKEN")
        login_or_registration()
    end

    {:ok, %{}}
  end

  defp login_or_registration() do
    case IO.gets("Would you like to login?(y/N)\n") |> String.trim() do
      "Y" ->
        follow_login()

      "y" ->
        follow_login()

      "N" ->
        register()

      "n" ->
        register()

      _ ->
        login_or_registration()
    end
  end

  defp register do
    case IO.gets("Would you like to register (y/N): ") |> String.trim() do
      "Y" ->
        RegistrationsController.register()

      "y" ->
        RegistrationsController.register()

      "N" ->
        Application.stop(:blackjack)

      "n" ->
        Application.stop(:blackjack)

      _ ->
        register()
    end
  end

  defp follow_login(username \\ nil) do
    servers_list = Core.list_servers()
    IO.inspect(username, label: "USERNAME")

    case AuthenticationController.login(%Plug.Conn{}, username) do
      {:ok, _response} ->
        if length(servers_list) > 0 do
          servers_list
        else
          case IO.gets("Would you like to create a server? (y/N)\n") |> String.trim() do
            "Y" ->
              IO.gets("What would you like to name this server?\n")
              |> String.trim()
              |> Core.create_server()

              format_servers(servers_list)

            "y" ->
              IO.gets("What would you like to name this server?\n")
              |> String.trim()
              |> Core.create_server()

              format_servers(servers_list)

            "N" ->
              format_servers(servers_list)

            "n" ->
              format_servers(servers_list)
          end
        end
    end
  end

  defp format_servers(servers_list) do
    servers = Enum.zip(1..Enum.count(servers_list), servers_list) |> IO.inspect()

    IO.puts("SERVERS")

    Enum.each(servers, fn {k, v} = _server ->
      IO.puts("#{k}) #{v}")
    end)
  end
end
