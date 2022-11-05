defmodule BlackjackWeb.Controllers.FriendshipsControllerTest do
  use Blackjack.RepoCase, async: false
  use Plug.Test

  alias Blackjack.Accounts.Authentication.Authentication

  alias Blackjack.Accounts.{
    AccountsRegistry,
    User,
    UserManager,
    Friendship,
    Friendships,
    FriendshipQuery
  }

  alias BlackjackWeb.Router
  alias Blackjack.Policy

  setup do
    users = build_pair(:user) |> set_password("password") |> insert_each()
    %{users: users}
  end

  describe "create/1" do
    test "current_user should send successful friend request", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user, token: current_user_token} = login_user(current_user)
      %{current_user: requested_user, token: requested_user_token} = login_user(requested_user)

      %{resp_body: response} =
        conn(
          :post,
          create_friendship_url(),
          %{uuid: requested_user.uuid} |> Jason.encode!()
        )
        |> put_req_header("authorization", "Bearer " <> current_user_token)
        |> put_req_header("content-type", "application/json")
        |> Router.call([])

      %{friendship: friendship} = response |> Jason.decode!(keys: :atoms)

      assert Bodyguard.permit?(Policy, :create_friendship, current_user, %Friendship{})

      assert current_user
             |> Repo.preload(friends: FriendshipQuery.pending_friends(current_user))
             |> Map.get(:friends) == [requested_user]

      assert current_user
             |> Repo.preload(friends: FriendshipQuery.accepted_friends(current_user))
             |> Map.get(:friends) == []
    end

    test "current_user should fail to send friend request", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user, token: current_user_token} = login_user(current_user)
      %{current_user: requested_user, token: requested_user_token} = login_user(requested_user)

      invalid_requested_user = %User{requested_user | uuid: Ecto.UUID.generate()}

      %{resp_body: response} =
        conn(
          :post,
          create_friendship_url(),
          %{uuid: invalid_requested_user.uuid} |> Jason.encode!()
        )
        |> put_req_header("authorization", "Bearer " <> current_user_token)
        |> put_req_header("content-type", "application/json")
        |> Router.call([])

      %{error: error_message} = response |> Jason.decode!(keys: :atoms)

      assert Bodyguard.permit?(Policy, :create_friendship, current_user, %Friendship{})

      assert error_message ==
               "Failed to create friendship, the requested user does not exist. Please try again later."
    end
  end

  describe "accept/1" do
    test "requested_user successfully accepts friend request from current_user", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user, token: current_user_token} = login_user(current_user)
      %{current_user: requested_user, token: requested_user_token} = login_user(requested_user)

      conn(:post, create_friendship_url(), %{uuid: requested_user.uuid} |> Jason.encode!())
      |> put_req_header("authorization", "Bearer " <> current_user_token)
      |> put_req_header("content-type", "application/json")
      |> Router.call([])

      requested_friendship =
        Repo.get_by(Friendship, user_uuid: requested_user.uuid, friend_uuid: current_user.uuid)

      conn(:post, accept_friendship_url(current_user))
      |> put_req_header("authorization", "Bearer " <> requested_user_token)
      |> Router.call([])

      assert Bodyguard.permit?(Policy, :accept_friendship, requested_user, requested_friendship)

      assert requested_user
             |> Repo.preload(friends: FriendshipQuery.accepted_friends(requested_user))
             |> Map.get(:friends)
             |> Enum.all?(&Enum.member?([current_user, requested_user], &1)) == true

      assert requested_user
             |> Repo.preload(friends: FriendshipQuery.pending_friends(requested_user))
             |> Map.get(:friends) == []

      assert requested_user
             |> Repo.preload(
               received_friends: FriendshipQuery.pending_received_friends(requested_user)
             )
             |> Map.get(:received_friends) == []

      assert requested_user
             |> Repo.preload(
               received_friends: FriendshipQuery.accepted_received_friends(requested_user)
             )
             |> Map.get(:received_friends)
             |> Enum.all?(&Enum.member?([current_user, requested_user], &1)) == true
    end

    test "requested_user fails to accept friend request from current_user", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user, token: current_user_token} = login_user(current_user)
      %{current_user: requested_user, token: requested_user_token} = login_user(requested_user)
      invalid_requested_user = %User{requested_user | uuid: Ecto.UUID.generate()}

      conn(
        :post,
        create_friendship_url(),
        %{uuid: invalid_requested_user.uuid} |> Jason.encode!()
      )
      |> put_req_header("authorization", "Bearer " <> current_user_token)
      |> put_req_header("content-type", "application/json")
      |> Router.call([])

      %{resp_body: response} =
        conn(:post, accept_friendship_url(current_user))
        |> put_req_header("authorization", "Bearer " <> requested_user_token)
        |> Router.call([])

      assert response |> Jason.decode!(keys: :atoms) == %{
               error:
                 "Failed to create friendship, the requested user does not exist. Please try again later."
             }
    end
  end

  describe "decline/1" do
    test "requested_user successfully declines friend request from current_user", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user, token: current_user_token} = login_user(current_user)
      %{current_user: requested_user, token: requested_user_token} = login_user(requested_user)

      conn(:post, create_friendship_url(), %{uuid: requested_user.uuid} |> Jason.encode!())
      |> put_req_header("authorization", "Bearer " <> current_user_token)
      |> put_req_header("content-type", "application/json")
      |> Router.call([])

      requested_friendship =
        Repo.get_by(Friendship, user_uuid: requested_user.uuid, friend_uuid: current_user.uuid)

      conn(:post, decline_friendship_url(current_user))
      |> put_req_header("authorization", "Bearer " <> requested_user_token)
      |> Router.call([])

      assert Bodyguard.permit?(Policy, :decline_friendship, requested_user, requested_friendship)

      assert current_user
             |> Repo.preload(friends: FriendshipQuery.pending_friends(current_user))
             |> Map.get(:friends) == []

      assert current_user
             |> Repo.preload(friends: FriendshipQuery.accepted_friends(current_user))
             |> Map.get(:friends) == []

      assert requested_user
             |> Repo.preload(
               received_friends: FriendshipQuery.pending_received_friends(current_user)
             )
             |> Map.get(:received_friends) == []

      assert requested_user
             |> Repo.preload(
               received_friends: FriendshipQuery.accepted_received_friends(current_user)
             )
             |> Map.get(:received_friends) == []
    end

    test "requested_user fails to decline friend request from current_user", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user, token: current_user_token} = login_user(current_user)
      %{current_user: requested_user, token: requested_user_token} = login_user(requested_user)
      invalid_requested_user = %User{requested_user | uuid: Ecto.UUID.generate()}

      conn(:post, create_friendship_url(), %{uuid: requested_user.uuid} |> Jason.encode!())
      |> put_req_header("authorization", "Bearer " <> current_user_token)
      |> put_req_header("content-type", "application/json")
      |> Router.call([])

      %{resp_body: response} =
        conn(:post, decline_friendship_url(current_user))
        |> put_req_header("authorization", "Bearer " <> requested_user_token)
        |> Router.call([])

      assert response |> Jason.decode!(keys: :atoms) == %{
               error:
                 "Failed to create friendship, the requested user does not exist. Please try again later."
             }
    end
  end

  describe "destroy/1" do
    test "should successfully remove requested_user from friends list", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user, token: current_user_token} = login_user(current_user)
      %{current_user: requested_user, token: requested_user_token} = login_user(requested_user)

      conn(:post, create_friendship_url(), %{uuid: requested_user.uuid} |> Jason.encode!())
      |> put_req_header("authorization", "Bearer " <> current_user_token)
      |> put_req_header("content-type", "application/json")
      |> Router.call([])

      conn(:post, accept_friendship_url(current_user))
      |> put_req_header("authorization", "Bearer " <> requested_user_token)
      |> Router.call([])

      requested_friendship =
        Repo.get_by(Friendship, user_uuid: current_user.uuid, friend_uuid: requested_user.uuid)

      conn(:delete, destroy_friendship_url(requested_user))
      |> put_req_header("authorization", "Bearer " <> current_user_token)
      |> Router.call([])

      assert Bodyguard.permit?(Policy, :remove_friendship, current_user, requested_friendship)

      assert current_user
             |> Repo.preload(friends: FriendshipQuery.accepted_friends(current_user))
             |> Map.get(:friends) == []

      assert requested_user
             |> Repo.preload(
               received_friends: FriendshipQuery.accepted_received_friends(current_user)
             )
             |> Map.get(:received_friends) == []
    end

    test "should fail to remove requested_user from friends list", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user, token: current_user_token} = login_user(current_user)
      %{current_user: requested_user, token: requested_user_token} = login_user(requested_user)
      invalid_requested_user = %User{requested_user | uuid: Ecto.UUID.generate()}

      conn(
        :post,
        create_friendship_url(),
        %{uuid: invalid_requested_user.uuid} |> Jason.encode!()
      )
      |> put_req_header("authorization", "Bearer " <> current_user_token)
      |> put_req_header("content-type", "application/json")
      |> Router.call([])

      conn(:post, accept_friendship_url(current_user))
      |> put_req_header("authorization", "Bearer " <> requested_user_token)
      |> Router.call([])

      requested_friendship =
        Repo.get_by(Friendship, user_uuid: current_user.uuid, friend_uuid: requested_user.uuid)

      %{resp_body: response} =
        conn(:delete, destroy_friendship_url(invalid_requested_user))
        |> put_req_header("authorization", "Bearer " <> current_user_token)
        |> Router.call([])

      assert response |> Jason.decode!(keys: :atoms) == %{
               error:
                 "Failed to create friendship, the requested user does not exist. Please try again later."
             }
    end
  end
end
