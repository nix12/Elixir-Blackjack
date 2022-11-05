defmodule BlackjackWeb.Controllers.AuthenticationControllerTest do
  @doctest BlackjackWeb.Controllers.AuthenticationController
  use Blackjack.RepoCase, async: false
  use Plug.Test

  alias BlackjackWeb.Controllers.AuthenticationController
  alias BlackjackWeb.Router

  setup do
    user = build(:user) |> set_password("password") |> insert()

    %{user: user}
  end

  describe "create/1" do
    test "succussful login with correct username and password", %{user: user} do
      %{current_user: current_user, token: current_user_token, info: {status, _}} =
        login_user(user)

      assert status == 200
      assert current_user_token
    end

    test "failure from wrong username and password" do
      user_params = %{email: "wrong@email.com", password_hash: "notpassword"}
      %{current_user: current_user, info: {status, body}} = login_user(user_params)

      assert status == 422
      assert %{"error" => "not found"} = body
    end
  end

  describe "destroy/1" do
    test "should logout current user", %{user: user} do
      %{current_user: current_user, token: current_user_token} = login_user(user)

      assert %{status: 200, body: "User is logged out."} = logout_user(current_user_token)
    end
  end
end
