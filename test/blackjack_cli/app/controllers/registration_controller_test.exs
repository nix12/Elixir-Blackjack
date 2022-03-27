defmodule BlackjackCli.Controllers.RegistrationControllerTest do
  @doctest BlackjackCli.Controllers.RegistrationController
  use Blackjack.RepoCase, async: true
  use Plug.Test

  alias BlackjackCli.Controllers.RegistrationController
  alias BlackjackCli.Router
  alias Blackjack.Accounts.User

  @register_path "http://localhost:#{Application.compile_env(:blackjack, :port)}/register"

  describe "#create" do
    test "succussful register with correct username and password" do
      user_params = %{
        user: %{
          username: "username",
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

    test "failure from wrong username and password" do
      build(:custom_user) |> User.insert()

      user_params = %{
        user: %{
          username: "username",
          password_hash: "password"
        }
      }

      conn = conn(:post, @register_path, user_params)
      response = Router.call(conn, [])

      assert response.state == :sent
      assert response.status == 500

      assert %{"errors" => "This username is already taken."} =
               response.resp_body |> Jason.decode!()
    end
  end
end
