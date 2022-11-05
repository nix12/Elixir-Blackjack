defmodule Blackjack.Accounts.FriendshipQueryTest do
  use Blackjack.RepoCase, async: false

  alias Blackjack.Accounts.{Friendship, Friendships, FriendshipQuery, AccountsRegistry}

  setup do
    users = build_pair(:user) |> set_password("password") |> insert_each()

    %{users: users}
  end

  describe "pending_friendship/2" do
    test "should return pending friendship", %{
      users: [current_user, requested_user | _empty]
    } do
      Friendships.create_friendships(current_user, requested_user)

      [pending, inverse] =
        FriendshipQuery.pending_friendship(current_user, requested_user)
        |> Repo.all()

      assert pending.user_uuid == current_user.uuid
      assert pending.friend_uuid == requested_user.uuid
      assert pending.pending == true
      assert pending.accepted == false

      assert inverse.user_uuid == requested_user.uuid
      assert inverse.friend_uuid == current_user.uuid
      assert inverse.pending == true
      assert inverse.accepted == false
    end
  end

  describe "accepted_friendship/2" do
    test "should return accepted friendship", %{
      users: [current_user, requested_user | _empty]
    } do
      Friendships.create_friendships(current_user, requested_user)
      Friendships.update_friendship(current_user, requested_user)

      [accepted, inverse] =
        FriendshipQuery.accepted_friendship(requested_user, current_user)
        |> Repo.all()

      assert accepted.user_uuid == current_user.uuid
      assert accepted.friend_uuid == requested_user.uuid
      assert accepted.pending == false
      assert accepted.accepted == true

      assert inverse.user_uuid == requested_user.uuid
      assert inverse.friend_uuid == current_user.uuid
      assert inverse.pending == false
      assert inverse.accepted == true
    end
  end

  describe "pending_friendships/1" do
    test "should return pending friendships", %{
      users: [current_user, requested_user | _empty]
    } do
      third_user = build(:user) |> set_password("password") |> insert()
      fourth_user = build(:user) |> set_password("password") |> insert()

      Friendships.create_friendships(current_user, requested_user)
      Friendships.create_friendships(current_user, third_user)

      friendships =
        FriendshipQuery.pending_friendships(current_user)
        |> Repo.all()

      assert friendships |> Enum.count() == 2

      assert friendships
             |> Enum.any?(fn friendship ->
               friendship.user_uuid == requested_user.uuid
             end)

      assert friendships
             |> Enum.any?(fn friendship -> friendship.user_uuid == third_user.uuid end)

      assert friendships
             |> Enum.any?(fn friendship -> friendship.user_uuid != fourth_user.uuid end)
    end
  end

  describe "accepted_friendships/1" do
    test "should return accepted friendships", %{
      users: [current_user, requested_user | _empty]
    } do
      third_user = build(:user) |> set_password("password") |> insert()
      fourth_user = build(:user) |> set_password("password") |> insert()

      Friendships.create_friendships(current_user, requested_user)
      Friendships.create_friendships(current_user, third_user)

      Friendships.update_friendship(current_user, requested_user)
      Friendships.update_friendship(current_user, third_user)

      friendships =
        FriendshipQuery.accepted_friendships(current_user)
        |> Repo.all()

      assert friendships |> Enum.count() == 2

      assert friendships
             |> Enum.any?(fn friendship ->
               friendship.user_uuid == requested_user.uuid
             end)

      assert friendships
             |> Enum.any?(fn friendship -> friendship.user_uuid == third_user.uuid end)

      assert friendships
             |> Enum.any?(fn friendship -> friendship.user_uuid != fourth_user.uuid end)
    end
  end

  describe "all_friendships/1" do
    test "should return all friendships", %{
      users: [current_user, requested_user | _empty]
    } do
      third_user = build(:user) |> set_password("password") |> insert()
      fourth_user = build(:user) |> set_password("password") |> insert()

      Friendships.create_friendships(current_user, requested_user)
      Friendships.create_friendships(current_user, third_user)

      Friendships.update_friendship(current_user, third_user)

      friendships =
        FriendshipQuery.all_friendships(current_user)
        |> Repo.all()

      assert friendships |> Enum.count() == 2

      assert friendships
             |> Enum.any?(fn friendship ->
               friendship.user_uuid == requested_user.uuid
             end)

      assert friendships
             |> Enum.any?(fn friendship -> friendship.user_uuid == third_user.uuid end)

      assert friendships
             |> Enum.any?(fn friendship -> friendship.user_uuid != fourth_user.uuid end)
    end
  end

  describe "pending_friends/1" do
    test "should return pending friends", %{
      users: [current_user, requested_user | _empty]
    } do
      Friendships.create_friendships(current_user, requested_user)

      friends =
        FriendshipQuery.pending_friends(current_user)
        |> Repo.all()

      assert friends |> Enum.count() == 1
      assert friends |> Enum.any?(&(&1 == requested_user))
    end
  end

  describe "accepted_friends/1" do
    test "should return accepted friends", %{
      users: [current_user, requested_user | _empty]
    } do
      Friendships.create_friendships(current_user, requested_user)
      Friendships.update_friendship(current_user, requested_user)

      friends =
        FriendshipQuery.accepted_friends(current_user)
        |> Repo.all()

      assert friends |> Enum.count() == 1
      assert friends |> Enum.any?(&(&1 == requested_user))
    end
  end

  describe "all_friends/1" do
    test "should return all friends", %{
      users: [current_user, requested_user | _empty]
    } do
      third_user = build(:user) |> set_password("password") |> insert()
      fourth_user = build(:user) |> set_password("password") |> insert()

      Friendships.create_friendships(current_user, requested_user)
      Friendships.create_friendships(current_user, third_user)

      Friendships.update_friendship(current_user, requested_user)
      Friendships.update_friendship(current_user, third_user)

      friends =
        FriendshipQuery.all_friends(current_user)
        |> Repo.all()

      assert friends |> Enum.count() == 2

      assert friends
             |> Enum.any?(fn friend -> friend == requested_user end)

      assert friends
             |> Enum.any?(fn friend -> friend == third_user end)

      assert friends
             |> Enum.any?(fn friend -> friend != fourth_user end)
    end
  end
end
