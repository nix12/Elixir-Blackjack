defmodule BlackjackWeb.Controllers.UsersControllerTest do
  @doctest BlackjackWeb.Controllers.UsersController
  use Blackjack.RepoCase, async: false
  use Plug.Test

  alias Blackjack.Repo
  alias Blackjack.Accounts.Authentication.Guardian
  alias Blackjack.Accounts.{User, UserManager, Policy}
  alias BlackjackWeb.Router

  @valid_change_params %{
    "user" => %{
      "email" => Faker.Internet.email(),
      "username" => Faker.Internet.user_name(),
      "password_hash" => "newpassword" |> Bcrypt.hash_pwd_salt()
    }
  }

  @invalid_change_params %{
    "user" => %{
      "email" => "",
      "username" => "",
      "password_hash" => ""
    }
  }

  setup do
    user = build(:user) |> set_password("password") |> insert()
    UserManager.start_link(user)

    update_user_path =
      "http://localhost:#{Application.get_env(:blackjack, :port)}/user/#{user.uuid}/update"

    {:ok, token, _claims} = Guardian.encode_and_sign(user)

    conn =
      conn(:put, update_user_path, @valid_change_params |> Jason.encode!())
      |> put_req_header("authorization", "Bearer " <> token)
      |> put_req_header("content-type", "application/json")

    %{conn: conn}
  end

  describe "#update" do
    test "succussfully update user" do
      conn = login_user() |> Router.call([])
      current_user = Guardian.Plug.current_resource(conn)
      token = Guardian.Plug.current_token(conn)
      login_user_path = "http://localhost:#{Application.get_env(:blackjack, :port)}/login"

      update_user_path =
        "http://localhost:#{Application.get_env(:blackjack, :port)}/user/#{current_user.uuid}/update"

      %User{email: email, username: username} =
        conn(:put, update_user_path, @valid_change_params |> Jason.encode!())
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Bearer " <> token)
        |> Router.call([])
        |> Guardian.Plug.current_resource()

      assert Bodyguard.permit?(Policy, :update_user, current_user, current_user.uuid)

      assert conn.state == :sent
      assert conn.status == 200

      refute current_user.password_hash ==
               @valid_change_params["user"]["password_hash"]

      assert email == @valid_change_params["user"]["email"]
      assert username == @valid_change_params["user"]["username"]
    end

    test "failure from wrong username and password", %{conn: conn} do
      conn = %{conn | params: @invalid_change_params, body_params: @invalid_change_params}
      response = Router.call(conn, [])
      current_user = Guardian.Plug.current_resource(response)

      assert Bodyguard.permit?(Policy, :update_user, current_user, current_user.uuid)

      assert response.status == 422

      assert %{"error" => "Failed to update account. Please try again."} =
               response.resp_body |> Jason.decode!()
    end

    test "update user from different account" do
      conn = login_user() |> Router.call([])
      current_user = Guardian.Plug.current_resource(conn)
      user2 = build(:user) |> set_password("password") |> insert()
      UserManager.start_link(user2)

      update_user_path =
        "http://localhost:#{Application.get_env(:blackjack, :port)}/user/#{user2.uuid}/update"

      token = Guardian.Plug.current_token(conn)

      updated_conn =
        conn(:put, update_user_path, @valid_change_params |> Jason.encode!())
        |> put_req_header("authorization", "Bearer " <> token)
        |> put_req_header("content-type", "application/json")
        |> Router.call([])

      %{"error" => error} = updated_conn.resp_body |> Jason.decode!()

      refute Bodyguard.permit?(Policy, :update_user, current_user, user2)

      assert updated_conn.status == 422
      assert error == "unauthorized"
    end
  end

  describe "#show" do
    test "must be logged in to view current user profile" do
      conn = login_user_show_path()
      response = Router.call(conn, [])
      current_user = Guardian.Plug.current_resource(response)

      assert Bodyguard.permit?(Policy, :show_user, current_user, current_user)

      assert response.status == 200

      assert response.assigns.user.email == current_user.email
      assert response.assigns.user.username == current_user.username
      assert response.assigns.user.uuid == current_user.uuid
    end

    test "must be logged in to view different user profile" do
      conn = login_user()
      response = Router.call(conn, [])
      current_user = Guardian.Plug.current_resource(response)
      user2 = build(:user) |> set_password("password") |> insert()

      show_user_path =
        "http://localhost:#{Application.get_env(:blackjack, :port)}/user/#{user2.uuid}"

      show_conn =
        conn(:get, show_user_path)
        |> put_req_header("authorization", "Bearer " <> Guardian.Plug.current_token(response))
        |> put_req_header("content-type", "application/json")

      show_response = Router.call(show_conn, [])

      assert Bodyguard.permit?(Policy, :show_user, current_user, user2)

      assert show_response.status == 200

      assert user2 != current_user
      assert show_response.assigns.user.email == user2.email
      assert show_response.assigns.user.username == user2.username
      assert show_response.assigns.user.uuid == user2.uuid
    end

    test "logged out user cannot view profiles" do
      login_path = "http://localhost:#{Application.get_env(:blackjack, :port)}/login"
      conn = conn(:get, login_path)
      response = Router.call(conn, [])

      requested_user =
        build(:user)
        |> set_password("password")
        |> insert()

      current_user = Guardian.Plug.current_resource(response)

      show_user_path =
        "http://localhost:#{Application.get_env(:blackjack, :port)}/user/#{requested_user.uuid}"

      show_conn = conn(:get, show_user_path, current_user |> Jason.encode!())
      show_response = Router.call(show_conn, [])

      refute Bodyguard.permit?(Policy, :show_user, current_user, current_user)

      assert show_response.status == 401

      assert show_response.resp_body != current_user
      assert show_response.resp_body |> Jason.decode!() == %{"message" => "unauthenticated"}
    end
  end

  def login_user_show_path do
    user = build(:user) |> set_password("password") |> insert()
    UserManager.start_link(user)

    show_user_path =
      "http://localhost:#{Application.get_env(:blackjack, :port)}/user/#{user.uuid}"

    {:ok, token, _claims} = Guardian.encode_and_sign(user)

    conn(:get, show_user_path)
    |> put_req_header("authorization", "Bearer " <> token)
    |> put_req_header("content-type", "application/json")
  end

  def login_user do
    user = build(:user) |> set_password("password") |> insert()

    user_params = %{
      user: %{
        email: user.email,
        password_hash: "password"
      }
    }

    login_user_path = "http://localhost:#{Application.get_env(:blackjack, :port)}/login"

    conn(:post, login_user_path, user_params |> Jason.encode!())
    |> put_req_header("content-type", "application/json")
  end
end
