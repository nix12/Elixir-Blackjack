defmodule UpdateUserTest do
  use Blackjack.RepoCase, async: false
  use Plug.Test

  alias Blackjack.Accounts.User
  alias Blackjack.Accounts.Supervisor, as: AccountsSupervisor
  alias Blackjack.Accounts.Authentication.Authentication

  setup do
    user = build(:user) |> set_password("password") |> insert()

    %{user: user}
  end

  describe "POST /:uuid/update" do
    test "SUCCESS", %{user: user} do
      %{current_user: current_user, token: current_user_token} = login_user(user)

      change_params = %{
        user: %{
          email: Faker.Internet.email(),
          username: Faker.Internet.user_name(),
          password_hash: "newpassword"
        }
      }

      %{current_user: updated_current_user, token: current_user_token, info: {status, _}} =
        update_user(current_user, change_params, current_user_token)

      assert status == 200

      refute change_params.user.email == user.email
      refute change_params.user.username == user.username
      refute change_params.user.password_hash == user.password_hash

      assert change_params.user.email == updated_current_user.email
      assert change_params.user.username == updated_current_user.username
      refute change_params.user.password_hash == updated_current_user.password_hash
    end

    test "failure!", %{user: user} do
      %{current_user: current_user, token: current_user_token} = login_user(user)
      change_params = %{user: %{email: "", username: "", password_hash: ""}}

      %{current_user: updated_current_user, token: current_user_token, info: {status, body}} =
        update_user(current_user, change_params, current_user_token)

      assert status == 422
      assert %{"error" => "Failed to update account. Please try again."} = body
    end
  end
end
