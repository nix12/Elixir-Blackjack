defmodule LoginUserTest do
  use Blackjack.RepoCase, async: false
  use Plug.Test
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Blackjack.Accounts.User

  setup do
    user = build(:user) |> set_password("password") |> insert()

    %{user: user}
  end

  setup do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")

    :ok
  end

  setup :verify_on_exit!

  describe "POST /login" do
    test "success!", %{user: user} do
      use_cassette "successful_user_login_request" do
        user_params = %{
          user: %{
            username: user.username,
            password_hash: "password"
          }
        }

        %HTTPoison.Response{
          body: body,
          status_code: status
        } = BlackjackCli.login_path(user_params)

        assert status == 200

        assert %{"token" => _, "user" => %{"username" => _, "password_hash" => _}} =
                 body |> Jason.decode!()
      end
    end

    test "failure!" do
      use_cassette "failed_user_login_request" do
        user_params = %{
          user: %{
            username: "",
            password_hash: ""
          }
        }

        %HTTPoison.Response{
          body: body,
          status_code: status
        } = BlackjackCli.login_path(user_params)

        assert status == 422
        assert %{"errors" => "invalid credentials"} = body |> Jason.decode!()
      end
    end
  end
end
