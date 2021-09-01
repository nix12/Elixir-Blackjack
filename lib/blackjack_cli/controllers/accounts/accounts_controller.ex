defmodule BlackjackCLI.Controllers.AccountsController do
  require Logger

  import Plug.Conn

  alias Blackjack.Accounts.Authentication.Guardian
  alias Blackjack.Repo
  alias Blackjack.Accounts.User
  alias Blackjack.Accounts

  @spec login(%{:params => map, optional(any) => any}) ::
          {:error, :invalid_credentials | <<_::64, _::_*8>>} | {:ok, Plug.Conn.t()}
  def login(
        %{
          :body_params => %{"user" => %{"username" => username, "password_hash" => password}}
        } = conn
      ) do
    case Accounts.authenticate_user(username, password) |> tap(&Logger.info(inspect(&1))) do
      {:error, message} ->
        {:error, message}

      {:ok, user} ->
        conn =
          conn
          |> Guardian.Plug.sign_in(user)
          |> assign(:user, user)
          |> then(&assign(&1, :token, Guardian.Plug.current_token(&1)))
          |> tap(&spawn_user(&1))
          |> tap(&get_user(&1))

        Logger.info("STILL FOUND USER: #{inspect(conn)}")
        {:ok, conn}
    end
  end

  @spec logout(Plug.Conn.t()) :: Plug.Conn.t()
  def logout(conn) do
    Guardian.Plug.sign_out(conn)
  end

  def register_user(conn) do
    changeset = User.changeset(%User{}, conn.body_params["user"])

    case Repo.insert(changeset) do
      {:ok, user} ->
        {:ok, user}

      {:error, %{errors: [{field, {error, _}}]}} ->
        {:errors, "#{field |> to_string} #{error}."}
    end
  end

  def spawn_user(conn) do
    Accounts.spawn_user(conn.assigns)
  end

  def get_user(conn) do
    Accounts.get_user(conn.assigns.user.uuid)
  end
end
