defmodule BlackjackCli.Controllers.AuthenticationControllerTest do
  @doctest BlackjackCli.Controllers.AuthenticationController
  use Blackjack.RepoCase
  use Plug.Test

  alias BlackjackCli.Controllers.AuthenticationController
  alias BlackjackCli.Router

  @login_path 'http://localhost:#{Application.get_env(:blackjack, :port)}/login'

  setup_all do
    Application.stop(:blackjack)
    :ok = Application.start(:blackjack)
  end

  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Blackjack.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Blackjack.Repo, {:shared, self()})
  end

  setup do
    build(:custom_user, username: "username") |> set_password("password") |> insert()
    :ok
  end

  describe "#create" do
    test "succussful login with correct email and password" do
      user_params = %{
        user: %{
          username: "username",
          password_hash: "password"
        }
      }

      conn = conn(:post, @login_path, user_params)
      response = Router.call(conn, [])

      assert response.state == :sent
      assert response.status == 200

      assert %{"token" => _, "user" => %{"username" => _, "password_hash" => _}} =
               response.resp_body |> Jason.decode!()
    end

    test "failure from wrong username and password" do
      user_params = %{
        user: %{
          username: "badname",
          password_hash: "notpassword"
        }
      }

      conn = conn(:post, @login_path, user_params)
      response = Router.call(conn, [])

      assert response.state == :sent
      assert response.status == 422
      assert %{"errors" => "invalid credentials"} = response.resp_body |> Jason.decode!()
    end
  end
end
