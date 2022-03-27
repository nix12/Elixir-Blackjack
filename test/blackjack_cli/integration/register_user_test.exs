defmodule RegisterUserTest do
  use Blackjack.RepoCase, async: false
  use Plug.Test
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Blackjack.Accounts.User

  setup do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  describe "POST /register" do
    test "success!" do
      use_cassette "successful_user_register_request" do
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
        } = BlackjackCli.register_path(user_params)

        assert status == 201

        assert %{
                 "user" => %{
                   "username" => _,
                   "password_hash" => _,
                   "inserted_at" => _,
                   "updated_at" => _
                 }
               } = body |> Jason.decode!()
      end
    end

    test "failure!" do
      use_cassette "failed_user_register_request" do
        user_params = %{
          user: %{
            username: "username",
            password_hash: "password"
          }
        }

        build(:custom_user) |> User.insert()

        %HTTPoison.Response{
          body: body,
          headers: _headers,
          status_code: status
        } = BlackjackCli.register_path(user_params)

        assert status == 500
        assert %{"errors" => "This username is already taken."} = body |> Jason.decode!()
      end
    end
  end
end
