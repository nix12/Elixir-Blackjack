defmodule BlackjackWeb.Controllers.UsersControllerTest do
  @doctest BlackjackWeb.Controllers.UsersController
  use Blackjack.RepoCase, async: false
  use Plug.Test

  alias Blackjack.Repo
  alias Blackjack.Accounts.Authentication.Authentication
  alias Blackjack.Policy
  alias Blackjack.Accounts.{User, UserManager}
  alias BlackjackWeb.Router

  @valid_change_params %{
    "user" => %{
      "email" => Faker.Internet.email(),
      "username" => Faker.Internet.user_name(),
      "password_hash" => "newpassword" |> Bcrypt.hash_pwd_salt()
    }
  }

  @invalid_change_params %{
    user: %{
      email: "",
      username: "",
      password_hash: ""
    }
  }

  setup do
    user = build(:user) |> set_password("password") |> insert()

    %{user: user}
  end

  describe "update/1" do
    test "succussfully update user", %{user: user} do
      %{current_user: current_user, token: current_user_token} = login_user(user)

      conn =
        conn(:put, update_user_url(current_user), @valid_change_params |> Jason.encode!())
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Bearer " <> current_user_token)
        |> Router.call([])

      %User{email: email, username: username} =
        conn
        |> Guardian.Plug.current_resource()

      assert Bodyguard.permit?(Policy, :update_user, current_user, current_user.id)

      assert conn.state == :sent
      assert conn.status == 200

      refute current_user.password_hash ==
               @valid_change_params["user"]["password_hash"]

      assert email == @valid_change_params["user"]["email"]
      assert username == @valid_change_params["user"]["username"]
    end

    test "failure from wrong username and password", %{user: user} do
      %{current_user: current_user, token: current_user_token} = login_user(user)

      %{current_user: updated_user, token: current_user_token, info: {status, body}} =
        update_user(current_user, @invalid_change_params, current_user_token)

      assert Bodyguard.permit?(Policy, :update_user, current_user, current_user.id)

      assert status == 422
      assert %{"error" => "Failed to update account. Please try again."} = body
    end

    test "update user from different account", %{user: user} do
      %{current_user: current_user, token: current_user_token} = login_user(user)

      %{current_user: requested_user, token: requested_user_token} =
        build(:user) |> set_password("password") |> insert() |> login_user()

      conn =
        conn(:put, update_user_url(requested_user), @valid_change_params |> Jason.encode!())
        |> put_req_header("authorization", "Bearer " <> current_user_token)
        |> put_req_header("content-type", "application/json")
        |> Router.call([])

      %{"error" => error} = conn.resp_body |> Jason.decode!()

      refute Bodyguard.permit?(Policy, :update_user, current_user, requested_user)

      assert conn.status == 422
      assert error == "unauthorized"
    end
  end

  describe "show/1" do
    test "must be logged in to view current user profile", %{user: user} do
      %{current_user: current_user, token: current_user_token} = login_user(user)

      conn =
        conn(:get, show_user_url(user))
        |> put_req_header("authorization", "Bearer " <> current_user_token)
        |> Router.call([])

      assert Bodyguard.permit?(Policy, :show_user, current_user, current_user)

      assert conn.status == 200
      assert conn.assigns.user.email == current_user.email
      assert conn.assigns.user.username == current_user.username
      assert conn.assigns.user.id == current_user.id
    end

    test "must be logged in to view different user profile", %{user: user} do
      %{current_user: current_user, token: current_user_token} = login_user(user)

      %{current_user: requested_user, token: requested_user_token} =
        build(:user) |> set_password("password") |> insert() |> login_user()

      conn =
        conn(:get, show_user_url(requested_user))
        |> put_req_header("authorization", "Bearer " <> current_user_token)
        |> Router.call([])

      assert Bodyguard.permit?(Policy, :show_user, current_user, requested_user)

      assert conn.status == 200

      assert requested_user != current_user
      assert conn.assigns.user.email == requested_user.email
      assert conn.assigns.user.username == requested_user.username
      assert conn.assigns.user.id == requested_user.id
    end

    test "logged out user cannot view profiles" do
      user = build(:user) |> set_password("password") |> insert()

      %{current_user: requested_user, token: requested_user_token} =
        build(:user) |> set_password("password") |> insert() |> login_user()

      conn = conn(:get, show_user_url(user)) |> Router.call([])

      assert conn.status == 401

      assert conn.resp_body != user
      assert conn.resp_body |> Jason.decode!() == %{"message" => "unauthenticated"}
    end

    test "should attempt to show an unregistered account" do
      requested_user = build(:user) |> set_password("password")

      %{current_user: current_user, token: current_user_token} =
        build(:user) |> set_password("password") |> insert() |> login_user()

      conn =
        conn(:get, show_user_url(requested_user))
        |> put_req_header("authorization", "Bearer " <> current_user_token)
        |> Router.call([])

      refute Bodyguard.permit?(Policy, :show_user, current_user, requested_user.id)

      assert conn.status == 401
      assert conn.resp_body != requested_user
      assert conn.resp_body |> Jason.decode!() == %{"message" => "unauthenticated"}
    end
  end
end
