defmodule LoginUserTest do
  use Blackjack.RepoCase, async: false
  use Plug.Test

  alias Blackjack.Accounts.User
  alias Blackjack.Accounts.Authentication.Guardian

  setup do
    user = build(:user) |> set_password("password") |> insert()

    %{user: user}
  end

  describe "POST /login" do
    test "success!", %{user: user} do
      user_params = %{
        user: %{
          email: user.email,
          password_hash: "password"
        }
      }

      %HTTPoison.Response{
        headers: [{_token_type, "Bearer " <> token} | _headers],
        status_code: status
      } = login_path(user_params)

      {:ok, current_user, _claims} = Guardian.resource_from_token(token)

      assert status == 200

      assert user == current_user
    end

    test "failure!" do
      user_params = %{
        user: %{
          email: "",
          password_hash: ""
        }
      }

      %HTTPoison.Response{body: body, status_code: status} = login_path(user_params)

      assert status == 422
      assert %{"error" => "not found"} = body |> Jason.decode!()
    end
  end
end
