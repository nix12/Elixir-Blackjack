defmodule BlackjackCli.Controllers.AuthenticationControllerTest do
  @doctest BlackjackCli.Controllers.AuthenticationController
  use Blackjack.RepoCase, async: true
  use Plug.Test

  alias BlackjackCli.Controllers.AuthenticationController
  alias BlackjackCli.Router
  alias Blackjack.Accounts.User

  @login_path "http://localhost:#{Application.compile_env(:blackjack, :port)}/login"

  setup do
    build(:custom_user) |> User.insert()

    :ok
  end

  describe "#create" do
    test "succussful login with correct username and password" do
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
