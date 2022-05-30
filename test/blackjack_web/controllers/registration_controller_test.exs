defmodule BlackjackWeb.Controllers.RegistrationControllerTest do
  @doctest BlackjackWeb.Controllers.RegistrationController
  use Blackjack.RepoCase, async: true
  use Plug.Test

  alias BlackjackWeb.Controllers.RegistrationController
  alias BlackjackWeb.Router

  @register_path "http://localhost:#{Application.compile_env(:blackjack, :port)}/register"

  describe "#create" do
    test "succussful register with correct username and password" do
      user_params = %{
        user: %{
          username: "username0",
          password_hash: "password"
        }
      }

      conn = conn(:post, @register_path, user_params)
      response = Router.call(conn, [])

      assert response.state == :sent
      assert response.status == 201

      assert %{
               "user" => %{
                 "username" => _,
                 "password_hash" => _,
                 "inserted_at" => _,
                 "updated_at" => _
               }
             } = response.resp_body |> Jason.decode!()
    end

    test "failure when registering an already registered user" do
      user = build(:user) |> set_password("password") |> insert()

      user_params = %{
        user: %{
          username: user.username,
          password_hash: "password"
        }
      }

      conn = conn(:post, @register_path, user_params)
      response = Router.call(conn, [])

      assert response.state == :sent
      assert response.status == 500

      assert %{"errors" => "username has already been taken."} =
               response.resp_body |> Jason.decode!()
    end
  end
end
