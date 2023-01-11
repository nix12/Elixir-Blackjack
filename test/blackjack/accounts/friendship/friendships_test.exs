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

      assert friendship.user_id == current_user.id
      assert friendship.friend_id == requested_user.id
      assert friendship.accepted == false
      assert friendship.pending == true

      assert inverse.user_id == requested_user.id
      assert inverse.friend_id == current_user.id
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

      assert friendship.user_id == current_user.id
      assert friendship.friend_id == requested_user.id
      assert friendship.accepted == true
      assert friendship.pending == false

      assert inverse.user_id == requested_user.id
      assert inverse.friend_id == current_user.id
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

      assert friendship.user_id == current_user.id
      assert friendship.friend_id == requested_user.id
      assert friendship.accepted == true
      assert friendship.pending == false

      assert inverse.user_id == requested_user.id
      assert inverse.friend_id == current_user.id
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
        :"create_friendship_#{current_user.id}_to_#{requested_user.id}"
      )

      {:ok, friendship} = Friendships.create_friendships(current_user, requested_user)

      Friendships.send_success(:create, current_user, requested_user, friendship)

      assert_received {:ok, friendship}

      assert capture_log(fn ->
               Logger.info(
                 "Friendship created between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}"
               )
             end) =~
               "Friendship created between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}"

      assert %{create_friendship: create} = friendship
      assert create.user_id == current_user.id
      assert create.friend_id == requested_user.id

      assert %{inverse_friendship: inverse} = friendship
      assert inverse.user_id == requested_user.id
      assert inverse.friend_id == current_user.id
    end

    test "should send message and log friendship acception", %{
      users: [current_user, requested_user | _empty]
    } do
      Process.register(
        self(),
        :"accept_friendship_#{current_user.id}_to_#{requested_user.id}"
      )

      Friendships.create_friendships(current_user, requested_user)

      {:ok, friendship} = Friendships.update_friendship(current_user, requested_user)

      Friendships.send_success(:accept, current_user, requested_user, friendship)

      assert_received {:ok, friendship}

      assert capture_log(fn ->
               Logger.info(
                 "Friendship accepted between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}"
               )
             end) =~
               "Friendship accepted between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}"

      assert %{update_current_user_friendship: accept} = friendship
      assert accept.user_id == current_user.id
      assert accept.friend_id == requested_user.id

      assert %{update_requested_user_friendship: inverse} = friendship
      assert inverse.user_id == requested_user.id
      assert inverse.friend_id == current_user.id
    end

    test "should send message and log friendship decline", %{
      users: [current_user, requested_user | _empty]
    } do
      Process.register(
        self(),
        :"decline_friendship_#{current_user.id}_to_#{requested_user.id}"
      )

      Friendships.create_friendships(current_user, requested_user)

      {:ok, friendship} = Friendships.remove_friendship(current_user, requested_user)

      Friendships.send_success(:decline, current_user, requested_user, friendship)

      assert_received {:ok, friendship}

      assert capture_log(fn ->
               Logger.info(
                 "Friendship declined between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}"
               )
             end) =~
               "Friendship declined between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}"

      assert %{remove_current_user_friendship: decline} = friendship
      assert decline.user_id == current_user.id
      assert decline.friend_id == requested_user.id

      assert %{remove_requested_user_friendship: inverse} = friendship
      assert inverse.user_id == requested_user.id
      assert inverse.friend_id == current_user.id
    end

    test "should send message and log friendship removal", %{
      users: [current_user, requested_user | _empty]
    } do
      Process.register(
        self(),
        :"remove_friendship_#{current_user.id}_to_#{requested_user.id}"
      )

      Friendships.create_friendships(current_user, requested_user)

      {:ok, friendship} = Friendships.remove_friendship(current_user, requested_user)

      Friendships.send_success(:remove, current_user, requested_user, friendship)

      assert_received {:ok, friendship}

      assert capture_log(fn ->
               Logger.info(
                 "Friendship removed between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}"
               )
             end) =~
               "Friendship removed between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}"

      assert %{remove_current_user_friendship: remove} = friendship
      assert remove.user_id == current_user.id
      assert remove.friend_id == requested_user.id

      assert %{remove_requested_user_friendship: inverse} = friendship
      assert inverse.user_id == requested_user.id
      assert inverse.friend_id == current_user.id
    end
  end

  describe "send_error/4" do
    test "should send message and error log for friendship creation", %{
      users: [current_user, requested_user | _empty]
    } do
      Process.register(
        self(),
        :"create_friendship_#{current_user.id}_to_#{requested_user.id}"
      )

      current_user = %User{current_user | id: Ecto.UUID.generate()}
      requested_user = %User{requested_user | id: Ecto.UUID.generate()}

      {:error, [{field_or_name, {error_message, constraint}}] = error} =
        Friendships.create_friendships(current_user, requested_user)

      Friendships.send_success(:create, current_user, requested_user, error)

      assert capture_log(fn ->
               Logger.error(
                 "Friendship creation error between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}, reason -> " <>
                   (field_or_name
                    |> Atom.to_string()) <> " " <> error_message
               )
             end) =~
               "Friendship creation error between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}, reason -> " <>
                 (field_or_name
                  |> Atom.to_string()) <> " " <> error_message
    end

    test "should send message and error log for friendship acception", %{
      users: [current_user, requested_user | _empty]
    } do
      Process.register(
        self(),
        :"accept_friendship_#{current_user.id}_to_#{requested_user.id}"
      )

      {:error, error} = Friendships.update_friendship(current_user, requested_user)

      Friendships.send_error(:accept, current_user, requested_user, error)

      assert capture_log(fn ->
               Logger.error(
                 "Accept friendship error between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}, reason -> " <>
                   inspect(error)
               )
             end) =~
               "Accept friendship error between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}, reason -> " <>
                 inspect(error)
    end

    test "should send message and error log for friendship decline", %{
      users: [current_user, requested_user | _empty]
    } do
      Process.register(
        self(),
        :"decline_friendship_#{current_user.id}_to_#{requested_user.id}"
      )

      {:error, error} = Friendships.remove_friendship(current_user, requested_user)

      Friendships.send_error(:decline, current_user, requested_user, error)

      assert capture_log(fn ->
               Logger.error(
                 "Friendship declined error between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}, reason -> " <>
                   inspect(error)
               )
             end) =~
               "Friendship declined error between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}, reason -> " <>
                 inspect(error)
    end

    test "should send message and error log for friendship removal", %{
      users: [current_user, requested_user | _empty]
    } do
      Process.register(
        self(),
        :"remove_friendship_#{current_user.id}_to_#{requested_user.id}"
      )

      {:error, error} = Friendships.remove_friendship(current_user, requested_user)

      Friendships.send_error(:remove, current_user, requested_user, error)

      assert capture_log(fn ->
               Logger.error(
                 "Friendship removal error between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}, reason -> " <>
                   inspect(error)
               )
             end) =~
               "Friendship removal error between #{current_user.id}: #{current_user.username} and #{requested_user.id}: #{requested_user.username}, reason -> " <>
                 inspect(error)
    end
  end
end
