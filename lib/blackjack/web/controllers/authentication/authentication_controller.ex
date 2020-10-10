defmodule Blackjack.Web.Controllers.AuthenticationController do
  alias Blackjack.Authentication.Guardian
  alias Blackjack.Repo
  alias Blackjack.Web.Models.User

  def token_file do
    "~/.blackjack_token"
  end

  def get_credentials do
    username =
      IO.gets("Enter username:\n")
      |> to_string()
      |> String.trim()

    IO.puts("Enter password:")
    password = :io.get_password()

    credentials = %{user: %{username: "#{username}", password_hash: "#{password}"}}

    System.cmd("curl", [
      "localhost:4000/login",
      "-s",
      "-X",
      "POST",
      "-H",
      "Content-Type: application/json",
      "-d",
      Jason.encode!(credentials)
    ])
  end

  def login(conn, %{"username" => username}) do
    case Repo.get_by(User, username: username) do
      nil ->
        get_credentials()

      resource ->
        conn
        |> Guardian.Plug.sign_in(resource, %{
          user: %{id: resource.id, username: resource.username}
        })
        |> Guardian.Plug.current_token()
    end
  end

  def store_token(token \\ "") do
    token_file()
    |> Path.expand()
    |> File.write(token, [:write])
  end

  def get_token do
    {:ok, token} =
      token_file()
      |> Path.expand()
      |> File.read()

    token
  end

  def logout(conn) do
    Guardian.Plug.sign_out(conn)
    System.cmd("rm", [token_file() |> Path.expand()])
  end
end
