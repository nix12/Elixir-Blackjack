defmodule ShowUserTest do
  use Blackjack.RepoCase, async: false
  use Plug.Test

  alias Blackjack.Repo
  alias Blackjack.Policy
  alias Blackjack.Accounts.{User, UserManager}
  alias Blackjack.Accounts.Authentication.Authentication

  setup do
    users = build_pair(:user) |> set_password("password") |> insert_each()

    for user <- users, do: UserManager.start_link(user)

    %{users: users}
  end

  describe "GET /:id" do
    test "SUCCESS", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user, token: current_user_token} = login_user(current_user)
      %{current_user: requested_user, token: requested_user_token} = login_user(requested_user)
      %{viewed_user: viewed_user, status: status} = show_user(current_user_token, requested_user)

      assert Bodyguard.permit?(Policy, :show_user, current_user, requested_user)

      assert status == 200

      assert viewed_user["email"] == requested_user.email
      assert viewed_user["username"] == requested_user.username
      assert viewed_user["id"] == requested_user.id
    end

    test "failure!", %{
      users: [_current_user, requested_user | _empty]
    } do
      invalid_current_user = %{email: "", password_hash: ""}

      %{current_user: current_user, token: current_user_token, info: {status, _}} =
        login_user(invalid_current_user)

      %{viewed_user: viewed_user, status: status} = show_user(current_user_token, requested_user)

      assert status == 401
      assert viewed_user == %{"message" => "unauthenticated"}
    end
  end
end
