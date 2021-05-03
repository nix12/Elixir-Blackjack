defmodule BlackjackWeb.Controllers.AuthenticationController do
  alias Blackjack.Authentication.Guardian
  alias Blackjack.Accounts

  def token_file do
    "~/.blackjack_token"
  end

  def get_credentials do
    username =
      IO.gets("Enter username: ")
      |> String.trim()

    password = Mix.Tasks.Hex.password_get("Enter password:") |> String.replace_trailing("\n", "")
    credentials = %{user: %{username: "#{username}", password_hash: "#{password}"}}

    send_credentials(credentials)
  end

  def login(conn, username \\ nil) do
    case (username == nil) |> IO.inspect(label: "BOOL") do
      true ->
        get_credentials()

      _ ->
        IO.inspect(username, label: "RESOURCE")

        conn
        |> Guardian.Plug.sign_in(username, %{
          user: %{username: username}
        })
        |> Guardian.Plug.current_token()
        |> Jason.decode!()
    end
  end

  def store_token(token \\ "") do
    token_file()
    |> Path.expand()
    |> File.write(token, [:write])
  end

  def get_token do
    if File.exists?(token_file() |> Path.expand()) |> IO.inspect(label: "EXISTENCE") do
      token_file()
      |> Path.expand()
      |> File.read()
      |> IO.inspect(label: "FILE")
    else
      {:ok, token, _claims} = Guardian.encode_and_sign(Jason.encode!(%{user: %{username: ""}}))

      {:error, token}
    end
  end

  def logout(conn) do
    Guardian.Plug.sign_out(conn)
    System.cmd("rm", [token_file() |> Path.expand()])
  end

  defp send_credentials(credentials) do
    {:ok, {response, _, _}} =
      :httpc.request(
        :post,
        {"http://localhost:#{Application.get_env(:blackjack, :port)}/login", [],
         'application/json', Jason.encode!(credentials)},
        [],
        []
      )

    {:ok, response}
  end
end
