defmodule UpdateUserTest do
  use Blackjack.RepoCase, async: false
  use Plug.Test

  alias Blackjack.Accounts.User
  alias Blackjack.Accounts.Supervisor, as: AccountsSupervisor
  alias Blackjack.Accounts.Authentication.Guardian

  setup do
    user = build(:user) |> set_password("password") |> insert()

    %{user: user}
  end

  describe "POST /:uuid/update" do
    test "SUCCESS", %{user: user} do
      change_params = %{
        user: %{
          email: Faker.Internet.email(),
          username: Faker.Internet.user_name(),
          password_hash: "newpassword"
        }
      }

      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      AccountsSupervisor.start_user(user)

      %HTTPoison.Response{
        body: body,
        headers: [{"authorization", "Bearer " <> token} | _headers],
        status_code: status
      } = update_user_path(%{user: user}, change_params, {"authorization", "Bearer " <> token})

      {:ok, updated_current_user, _claims} = Guardian.resource_from_token(token)

      assert status == 200

      refute change_params.user.email == user.email
      refute change_params.user.username == user.username
      refute change_params.user.password_hash == user.password_hash

      assert change_params.user.email == updated_current_user.email
      assert change_params.user.username == updated_current_user.username
      refute change_params.user.password_hash == updated_current_user.password_hash
    end

    test "failure!", %{user: user} do
      change_params = %{user: %{email: "", username: "", password_hash: ""}}

      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      AccountsSupervisor.start_user(user)

      %HTTPoison.Response{body: body, status_code: status} =
        update_user_path(%{user: user}, change_params, {"authorization", "Bearer " <> token})

      assert status == 422
      assert %{"error" => "Failed to update account. Please try again."} = body |> Jason.decode!()
    end
  end
end
