defmodule LoginUserTest do
  use Blackjack.RepoCase, async: false
  use Plug.Test

  alias Blackjack.Accounts.User
  alias Blackjack.Accounts.Authentication.Authentication

  setup do
    user = build(:user) |> set_password("password") |> insert()

    %{user: user}
  end

  describe "POST /login" do
    test "success!", %{user: user} do
      %{current_user: current_user, info: {status, _}} = login_user(user)

      assert status == 200
      assert user == current_user
    end

    test "failure!" do
      user_params = %{email: "", password_hash: ""}
      %{current_user: current_user, info: {status, body}} = login_user(user_params)

      assert status == 422
      assert %{"error" => "not found"} = body
    end
  end
end
