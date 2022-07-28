defmodule BlackjackWeb.Controllers.FriendshipsControllerTest do
  use Blackjack.RepoCase, async: false
  use Plug.Test

  alias Blackjack.Repo
  alias Blackjack.Accounts.Authentication.Guardian

  alias Blackjack.Accounts.{
    AccountsRegistry,
    User,
    UserManager,
    Friendship,
    Friendships,
    FriendshipQuery,
    Policy
  }

  alias BlackjackWeb.Router

  setup do
    users = build_pair(:user) |> set_password("password") |> insert_each()

    for user <- users, do: UserManager.start_link(user)

    %{users: users}
  end

  describe "#create" do
    test "current_user sends successful friend request", %{users: [user1, user2 | _empty]} do
      login_params = %{user: %{email: user1.email, password_hash: user1.password_hash}}

      %HTTPoison.Response{
        headers: [{"authorization", "Bearer " <> token} | _headers],
        status_code: 200
      } = login_path(login_params)

      {:ok, current_user, _claims} = Guardian.resource_from_token(token)

      friendship_url =
        "http://localhost:" <>
          (Application.get_env(:blackjack, :port) |> to_string()) <> "/friendship/create"

      response =
        conn(
          :post,
          friendship_url,
          %{uuid: user2.uuid} |> Jason.encode!()
        )
        |> put_req_header("authorization", "Bearer " <> token)
        |> put_req_header("content-type", "application/json")
        |> Router.call([])

      assert Bodyguard.permit?(Policy, :create_friendship, current_user, user2)

      assert response.state == :sent
      assert response.status == 201

      assert current_user
             |> Repo.preload(:friends)
             |> Map.get(:friends)
             |> List.first() == user2

      assert current_user
             |> Repo.preload(:friends)
             |> Map.get(:friends)
             |> Enum.count() == 1

      assert current_user
             |> Repo.preload(friends: FriendshipQuery.accepted_friendships(current_user))
             |> Map.get(:friends)
             |> Enum.count() == 0

      assert current_user
             |> Repo.preload(:friends)
             |> Map.get(:friends)
             |> Enum.count() == 1
    end

    # test "requested_user successfully accepts friend request from current_user", %{users: users} do
    # end

    # test "current_user successfully adds friend", %{users: users} do
    # end
  end
end
