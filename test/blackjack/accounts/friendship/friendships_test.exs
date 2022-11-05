defmodule Blackjack.Accounts.FriendshipsTest do
  require Logger

  use Blackjack.RepoCase, async: false

  import ExUnit.CaptureLog

  alias Blackjack.Accounts.{User, Friendship, Friendships}

  setup do
    users = build_pair(:user) |> set_password("password") |> insert_each()

    %{users: users}
  end

  describe "create_friendships/2" do
    test "should create a new friendship as well as the inverse of the friendship", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user} = login_user(current_user)
      %{current_user: requested_user} = login_user(requested_user)

      assert {:ok, %{create_friendship: friendship, inverse_friendship: inverse}} =
               Friendships.create_friendships(current_user, requested_user)

      assert friendship.user_uuid == current_user.uuid
      assert friendship.friend_uuid == requested_user.uuid
      assert friendship.accepted == false
      assert friendship.pending == true

      assert inverse.user_uuid == requested_user.uuid
      assert inverse.friend_uuid == current_user.uuid
      assert inverse.accepted == false
      assert inverse.pending == true
    end
  end

  describe "update_friendship/2" do
    test "should successfully update a friendship", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user} = login_user(current_user)
      %{current_user: requested_user} = login_user(requested_user)

      Friendships.create_friendships(current_user, requested_user)

      assert {:ok,
              %{
                update_current_user_friendship: friendship,
                update_requested_user_friendship: inverse
              }} = Friendships.update_friendship(current_user, requested_user)

      assert friendship.user_uuid == current_user.uuid
      assert friendship.friend_uuid == requested_user.uuid
      assert friendship.accepted == true
      assert friendship.pending == false

      assert inverse.user_uuid == requested_user.uuid
      assert inverse.friend_uuid == current_user.uuid
      assert inverse.accepted == true
      assert inverse.pending == false
    end

    test "should fail to update a friendship", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user} = login_user(current_user)
      %{current_user: requested_user} = login_user(requested_user)

      assert {:error, {:failed_update, :user_not_found}} =
               Friendships.update_friendship(current_user, requested_user)

      assert {:error, {:failed_update, :user_not_found}} =
               Friendships.update_friendship(requested_user, current_user)
    end
  end

  describe "remove_friendship/2" do
    test "should successfully remove a friendship", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user} = login_user(current_user)
      %{current_user: requested_user} = login_user(requested_user)

      Friendships.create_friendships(current_user, requested_user)

      assert {:ok,
              %{
                remove_current_user_friendship: friendship,
                remove_requested_user_friendship: inverse
              }} = Friendships.remove_friendship(current_user, requested_user)

      assert friendship.user_uuid == current_user.uuid
      assert friendship.friend_uuid == requested_user.uuid
      assert friendship.accepted == true
      assert friendship.pending == false

      assert inverse.user_uuid == requested_user.uuid
      assert inverse.friend_uuid == current_user.uuid
      assert inverse.accepted == true
      assert inverse.pending == false
    end

    test "should fail to remove an invalid friendship", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user} = login_user(current_user)
      %{current_user: requested_user} = login_user(requested_user)

      assert {:error, {:failed_delete, :user_not_found}} =
               Friendships.remove_friendship(current_user, requested_user)

      assert {:error, {:failed_delete, :user_not_found}} =
               Friendships.remove_friendship(requested_user, current_user)
    end
  end

  describe "send_success/4" do
    test "should send message and log friendship creation", %{
      users: [current_user, requested_user | _empty]
    } do
      Process.register(
        self(),
        :"create_friendship_#{current_user.uuid}_to_#{requested_user.uuid}"
      )

      {:ok, friendship} = Friendships.create_friendships(current_user, requested_user)

      Friendships.send_success(:create, current_user, requested_user, friendship)

      assert_received {:ok, friendship}

      assert capture_log(fn ->
               Logger.info(
                 "Friendship created between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
               )
             end) =~
               "Friendship created between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"

      assert %{create_friendship: create} = friendship
      assert create.user_uuid == current_user.uuid
      assert create.friend_uuid == requested_user.uuid

      assert %{inverse_friendship: inverse} = friendship
      assert inverse.user_uuid == requested_user.uuid
      assert inverse.friend_uuid == current_user.uuid
    end

    test "should send message and log friendship acception", %{
      users: [current_user, requested_user | _empty]
    } do
      Process.register(
        self(),
        :"accept_friendship_#{current_user.uuid}_to_#{requested_user.uuid}"
      )

      Friendships.create_friendships(current_user, requested_user)

      {:ok, friendship} = Friendships.update_friendship(current_user, requested_user)

      Friendships.send_success(:accept, current_user, requested_user, friendship)

      assert_received {:ok, friendship}

      assert capture_log(fn ->
               Logger.info(
                 "Friendship accepted between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
               )
             end) =~
               "Friendship accepted between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"

      assert %{update_current_user_friendship: accept} = friendship
      assert accept.user_uuid == current_user.uuid
      assert accept.friend_uuid == requested_user.uuid

      assert %{update_requested_user_friendship: inverse} = friendship
      assert inverse.user_uuid == requested_user.uuid
      assert inverse.friend_uuid == current_user.uuid
    end

    test "should send message and log friendship decline", %{
      users: [current_user, requested_user | _empty]
    } do
      Process.register(
        self(),
        :"decline_friendship_#{current_user.uuid}_to_#{requested_user.uuid}"
      )

      Friendships.create_friendships(current_user, requested_user)

      {:ok, friendship} = Friendships.remove_friendship(current_user, requested_user)

      Friendships.send_success(:decline, current_user, requested_user, friendship)

      assert_received {:ok, friendship}

      assert capture_log(fn ->
               Logger.info(
                 "Friendship declined between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
               )
             end) =~
               "Friendship declined between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"

      assert %{remove_current_user_friendship: decline} = friendship
      assert decline.user_uuid == current_user.uuid
      assert decline.friend_uuid == requested_user.uuid

      assert %{remove_requested_user_friendship: inverse} = friendship
      assert inverse.user_uuid == requested_user.uuid
      assert inverse.friend_uuid == current_user.uuid
    end

    test "should send message and log friendship removal", %{
      users: [current_user, requested_user | _empty]
    } do
      Process.register(
        self(),
        :"remove_friendship_#{current_user.uuid}_to_#{requested_user.uuid}"
      )

      Friendships.create_friendships(current_user, requested_user)

      {:ok, friendship} = Friendships.remove_friendship(current_user, requested_user)

      Friendships.send_success(:remove, current_user, requested_user, friendship)

      assert_received {:ok, friendship}

      assert capture_log(fn ->
               Logger.info(
                 "Friendship removed between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
               )
             end) =~
               "Friendship removed between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"

      assert %{remove_current_user_friendship: remove} = friendship
      assert remove.user_uuid == current_user.uuid
      assert remove.friend_uuid == requested_user.uuid

      assert %{remove_requested_user_friendship: inverse} = friendship
      assert inverse.user_uuid == requested_user.uuid
      assert inverse.friend_uuid == current_user.uuid
    end
  end

  describe "send_error/4" do
    test "should send message and error log for friendship creation", %{
      users: [current_user, requested_user | _empty]
    } do
      Process.register(
        self(),
        :"create_friendship_#{current_user.uuid}_to_#{requested_user.uuid}"
      )

      current_user = %User{current_user | uuid: Ecto.UUID.generate()}
      requested_user = %User{requested_user | uuid: Ecto.UUID.generate()}

      {:error, [{field_or_name, {error_message, constraint}}] = error} =
        Friendships.create_friendships(current_user, requested_user)

      Friendships.send_success(:create, current_user, requested_user, error)

      assert capture_log(fn ->
               Logger.error(
                 "Friendship creation error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                   (field_or_name
                    |> Atom.to_string()) <> " " <> error_message
               )
             end) =~
               "Friendship creation error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                 (field_or_name
                  |> Atom.to_string()) <> " " <> error_message
    end

    test "should send message and error log for friendship acception", %{
      users: [current_user, requested_user | _empty]
    } do
      Process.register(
        self(),
        :"accept_friendship_#{current_user.uuid}_to_#{requested_user.uuid}"
      )

      {:error, error} = Friendships.update_friendship(current_user, requested_user)

      Friendships.send_error(:accept, current_user, requested_user, error)

      assert capture_log(fn ->
               Logger.error(
                 "Accept friendship error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                   inspect(error)
               )
             end) =~
               "Accept friendship error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                 inspect(error)
    end

    test "should send message and error log for friendship decline", %{
      users: [current_user, requested_user | _empty]
    } do
      Process.register(
        self(),
        :"decline_friendship_#{current_user.uuid}_to_#{requested_user.uuid}"
      )

      {:error, error} = Friendships.remove_friendship(current_user, requested_user)

      Friendships.send_error(:decline, current_user, requested_user, error)

      assert capture_log(fn ->
               Logger.error(
                 "Friendship declined error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                   inspect(error)
               )
             end) =~
               "Friendship declined error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                 inspect(error)
    end

    test "should send message and error log for friendship removal", %{
      users: [current_user, requested_user | _empty]
    } do
      Process.register(
        self(),
        :"remove_friendship_#{current_user.uuid}_to_#{requested_user.uuid}"
      )

      {:error, error} = Friendships.remove_friendship(current_user, requested_user)

      Friendships.send_error(:remove, current_user, requested_user, error)

      assert capture_log(fn ->
               Logger.error(
                 "Friendship removal error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                   inspect(error)
               )
             end) =~
               "Friendship removal error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                 inspect(error)
    end
  end
end
