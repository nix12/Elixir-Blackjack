defmodule BlackjackWeb.Controllers.AuthenticationControllerTest do
  @doctest BlackjackWeb.Controllers.AuthenticationController
  use Blackjack.RepoCase, async: false
  use Plug.Test

  alias BlackjackWeb.Controllers.AuthenticationController
  alias BlackjackWeb.Router

  @login_path "http://localhost:#{Application.compile_env(:blackjack, :port)}/login"

  setup do
    user = build(:user) |> set_password("password") |> insert()

    %{user: user}
  end

  describe "#create" do
    test "succussful login with correct username and password", %{user: user} do
      user_params = %{
        user: %{
          email: user.email,
          password_hash: "password"
        }
      }

      conn = conn(:post, @login_path, user_params)
      response = Router.call(conn, [])

      assert response.state == :sent
      assert response.status == 200

      assert [_, {"authorization", _}] = response.resp_headers
    end

    test "failure from wrong username and password" do
      user_params = %{
        user: %{
          email: "wrong@email.com",
          password_hash: "notpassword"
        }
      }

      conn = conn(:post, @login_path, user_params)
      response = Router.call(conn, [])

      assert response.status == 422
      assert %{"error" => "not found"} = response.resp_body |> Jason.decode!()
    end
  end
end
