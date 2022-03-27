defmodule LoginUserTest do
  use Blackjack.RepoCase, async: false
  use Plug.Test
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Blackjack.Accounts.User

  setup do
    build(:custom_user) |> User.insert()
    :ok
  end

  setup do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  describe "POST /login" do
    test "success!" do
      use_cassette "successful_user_login_request" do
        user_params = %{
          user: %{
            username: "username",
            password_hash: "password"
          }
        }

        %HTTPoison.Response{
          body: body,
          headers: _headers,
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
          headers: _headers,
          status_code: status
        } = BlackjackCli.login_path(user_params)

        assert status == 422
        assert %{"errors" => "invalid credentials"} = body |> Jason.decode!()
      end
    end
  end
end
