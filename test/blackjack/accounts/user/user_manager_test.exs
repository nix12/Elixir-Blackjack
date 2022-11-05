defmodule Blackjack.Accounts.UserManagerTest do
  require Logger

  use Blackjack.RepoCase, async: false

  import ExUnit.CaptureLog

  alias Blackjack.Accounts.{
    User,
    UserManager,
    Friendship,
    Friendships,
    FriendshipQuery,
    AccountsRegistry,
    Inbox
  }

  alias Blackjack.Notifiers.AccountsNotifier
  alias Blackjack.Accounts.Supervisor, as: AccountsSupervisor
  alias Blackjack.Communications.Notifications.Notification
  alias Blackjack.Accounts.Inbox.InboxesNotifications

  setup do
    users = build_pair(:user) |> set_password("password") |> insert_each([:with_inbox])

    %{users: users}
  end

  describe "UserManager" do
    test "init/1", %{users: [current_user, requested_user | _empty]} do
      {:ok, current_user} =
        UserManager.init(%{
          uuid: current_user.uuid,
          email: current_user.email,
          username: current_user.username,
          password_hash: current_user.password_hash,
          inserted_at: current_user.inserted_at,
          updated_at: current_user.updated_at
        })

      assert %{
               uuid: current_user.uuid,
               email: current_user.email,
               username: current_user.username,
               password_hash: current_user.password_hash,
               inserted_at: current_user.inserted_at,
               updated_at: current_user.updated_at
             } ==
               current_user
    end

    test "get_user", %{users: [current_user, requested_user | _empty]} do
      {:reply, response, new_state} = UserManager.handle_call({:get_user}, nil, current_user)

      assert response == new_state
    end

    test "update_user", %{users: [current_user, requested_user | _empty]} do
      %{current_user: current_user} = login_user(current_user)

      change_params = %{
        uuid: current_user.uuid,
        email: Faker.Internet.email(),
        username: Faker.Internet.user_name(),
        password_hash: "newpassword"
      }

      [{current_user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, current_user.uuid)
      send(current_user_pid, {:update_user, [change_params]})
      :timer.sleep(250)

      assert capture_log(fn ->
               Logger.info("Updated user " <> current_user.uuid)
             end) =~ "Updated user " <> current_user.uuid

      assert current_user.uuid == change_params.uuid
      refute current_user.email == change_params.email
      refute current_user.username == change_params.username
      refute current_user.password_hash == change_params.password_hash
    end

    test "stop_user", %{users: [current_user, requested_user | _empty] = users} do
      %{current_user: current_user} = login_user(current_user)
      [{current_user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, current_user.uuid)

      send(current_user_pid, {:stop_user, []})
      Process.sleep(50)
      refute Process.alive?(current_user_pid)
    end

    test "create_friendship success", %{users: [current_user, requested_user | _empty]} do
      %{current_user: current_user} = login_user(current_user)
      [{current_user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, current_user.uuid)

      Task.async(fn ->
        Process.register(
          self(),
          :"create_friendship_#{current_user.uuid}_to_#{requested_user.uuid}"
        )

        send(current_user_pid, {:create_friendship, [requested_user]})

        receive do
          {:ok, friendship} ->
            assert capture_log(fn ->
                     Logger.info(
                       "Friendship created between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
                     )
                   end) =~
                     "Friendship created between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
        end
      end)
      |> Task.await()

      assert Repo.all(Friendship) |> Enum.count() == 2

      assert current_user |> Repo.preload(:friends) |> Map.get(:friends) ==
               [requested_user]

      assert current_user
             |> Repo.preload(:received_friends)
             |> Map.get(:received_friends) ==
               [requested_user]

      assert requested_user |> Repo.preload(:friends) |> Map.get(:friends) == [current_user]

      assert requested_user |> Repo.preload(:received_friends) |> Map.get(:received_friends) == [
               current_user
             ]
    end

    test "create_friendship failure by invalid friend_uuid", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user} = login_user(current_user)
      [{current_user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, current_user.uuid)
      invalid_requested_user = %User{requested_user | uuid: Ecto.UUID.generate()}

      error =
        Task.Supervisor.async(Blackjack.TaskSupervisor, fn ->
          Process.register(
            self(),
            :"create_friendship_#{current_user.uuid}_to_#{invalid_requested_user.uuid}"
          )

          send(
            current_user_pid,
            {:create_friendship, [invalid_requested_user]}
          )

          receive do
            {:error, error_message} ->
              assert capture_log(fn ->
                       Logger.error(
                         "Friendship creation error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                           error_message
                       )
                     end) =~
                       "Friendship creation error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                         error_message

              error_message
          end
        end)
        |> Task.await()

      assert Repo.all(Friendship) |> Enum.count() == 0
      assert error == "One of these fields UUID does not exist: [:user_uuid, :friend_uuid]"
    end

    test "create_friendship failure by creating an already created friendship", %{
      users: [current_user, requested_user | _empty]
    } do
      %{current_user: current_user} = login_user(current_user)
      [{current_user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, current_user.uuid)

      Friendships.create_friendships(current_user, requested_user)

      error =
        Task.Supervisor.async(Blackjack.TaskSupervisor, fn ->
          Process.register(
            self(),
            :"create_friendship_#{current_user.uuid}_to_#{requested_user.uuid}"
          )

          send(
            current_user_pid,
            {:create_friendship, [requested_user]}
          )

          receive do
            {:error, error_message} ->
              assert capture_log(fn ->
                       Logger.error(
                         "Friendship creation error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                           error_message
                       )
                     end) =~
                       "Friendship creation error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                         error_message

              error_message
          end
        end)
        |> Task.await()

      assert Repo.all(Friendship) |> Enum.count() == 2
      assert error == "user_uuid has already been taken."
    end

    test "friend_request", %{users: [current_user, requested_user | _empty] = users} do
      %{current_user: current_user} = login_user(current_user)
      [{current_user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, current_user.uuid)

      send(current_user_pid, {:friend_request, requested_user})
      :timer.sleep(250)

      assert capture_log(fn ->
               Logger.info("Friend request sent to: " <> requested_user.username)
             end) =~ "Friend request sent to: " <> requested_user.username

      assert Repo.all(Notification) |> Enum.count() == 1

      assert requested_user
             |> Repo.preload(inbox: :notifications)
             |> get_in([Access.key(:inbox), Access.key(:notifications)])
             |> Enum.count() == 1

      assert requested_user
             |> Repo.preload(inbox: :notifications)
             |> get_in([Access.key(:inbox), Access.key(:notifications)])
             |> Enum.at(0)
             |> Map.get(:body) == "Friend request from: " <> current_user.username

      assert requested_user
             |> Repo.preload(inbox: :notifications)
             |> get_in([Access.key(:inbox), Access.key(:notifications)])
             |> Enum.at(0)
             |> Map.get(:read) == false

      assert requested_user
             |> Repo.preload(inbox: :notifications)
             |> get_in([Access.key(:inbox), Access.key(:notifications)])
             |> Enum.at(0)
             |> Map.get(:user_uuid) == requested_user.uuid
    end

    test "accept_friendship success", %{users: [current_user, requested_user | _empty] = users} do
      %{current_user: current_user} = login_user(current_user)
      %{current_user: requested_user} = login_user(requested_user)
      [{requested_user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, requested_user.uuid)

      Friendships.create_friendships(current_user, requested_user)

      Task.async(fn ->
        Process.register(
          self(),
          :"accept_friendship_#{requested_user.uuid}_to_#{current_user.uuid}"
        )

        send(requested_user_pid, {:accept_friendship, [current_user]})

        receive do
          {:ok, friendship} ->
            assert capture_log(fn ->
                     Logger.info(
                       "Friendship accepted between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
                     )
                   end) =~
                     "Friendship accepted between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
        end
      end)
      |> Task.await()

      assert Repo.all(
               Ecto.Query.from(friendship in Friendship, where: friendship.pending == true)
             ) == []

      assert Repo.all(
               Ecto.Query.from(friendship in Friendship, where: friendship.accepted == true)
             )
             |> Enum.count() == 2

      assert current_user |> Repo.preload(:friends) |> Map.get(:friends) == [requested_user]
      assert requested_user |> Repo.preload(:friends) |> Map.get(:friends) == [current_user]
    end

    test "accept_friendship failure", %{users: [current_user, requested_user | _empty] = users} do
      %{current_user: current_user} = login_user(current_user)
      %{current_user: requested_user} = login_user(requested_user)
      [{current_user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, current_user.uuid)
      invalid_requested_user = %User{requested_user | uuid: Ecto.UUID.generate()}

      error =
        Task.async(fn ->
          Process.register(
            self(),
            :"accept_friendship_#{current_user.uuid}_to_#{invalid_requested_user.uuid}"
          )

          send(current_user_pid, {:accept_friendship, [invalid_requested_user]})

          receive do
            {:error, error_message} ->
              assert capture_log(fn ->
                       Logger.error(
                         "Accept friendship error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                           error_message
                       )
                     end) =~
                       "Accept friendship error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                         error_message

              error_message
          end
        end)
        |> Task.await()

      assert Repo.all(
               Ecto.Query.from(friendship in Friendship, where: friendship.pending == true)
             ) == []

      assert Repo.all(
               Ecto.Query.from(friendship in Friendship, where: friendship.accepted == true)
             ) == []

      assert error ==
               "Failed to accept friend request because user not found. Please try again later."
    end

    test "decline_friendship success", %{users: [current_user, requested_user | _empty] = users} do
      %{current_user: current_user} = login_user(current_user)
      %{current_user: requested_user} = login_user(requested_user)
      [{requested_user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, requested_user.uuid)

      Friendships.create_friendships(current_user, requested_user)

      Task.async(fn ->
        Process.register(
          self(),
          :"decline_friendship_#{requested_user.uuid}_to_#{current_user.uuid}"
        )

        send(requested_user_pid, {:decline_friendship, [current_user]})

        receive do
          {:ok, friendship} ->
            assert capture_log(fn ->
                     Logger.info(
                       "Friendship declined between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
                     )
                   end) =~
                     "Friendship declined between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
        end
      end)
      |> Task.await()

      assert Repo.all(
               Ecto.Query.from(friendship in Friendship, where: friendship.pending == true)
             ) == []

      assert current_user |> Repo.preload(:friends) |> Map.get(:friends) == []
      assert requested_user |> Repo.preload(:friends) |> Map.get(:friends) == []
    end

    test "decline_friendship failure", %{users: [current_user, requested_user | _empty] = users} do
      %{current_user: current_user} = login_user(current_user)
      %{current_user: requested_user} = login_user(requested_user)
      [{current_user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, current_user.uuid)
      invalid_requested_user = %User{requested_user | uuid: Ecto.UUID.generate()}

      error =
        Task.async(fn ->
          Process.register(
            self(),
            :"decline_friendship_#{current_user.uuid}_to_#{invalid_requested_user.uuid}"
          )

          send(current_user_pid, {:decline_friendship, [invalid_requested_user]})

          receive do
            {:error, error_message} ->
              assert capture_log(fn ->
                       Logger.error(
                         "Decline friendship error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                           error_message
                       )
                     end) =~
                       "Decline friendship error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                         error_message

              error_message
          end
        end)
        |> Task.await()

      assert Repo.all(
               Ecto.Query.from(friendship in Friendship, where: friendship.pending == true)
             ) == []

      assert Repo.all(
               Ecto.Query.from(friendship in Friendship, where: friendship.accepted == true)
             ) == []

      assert error ==
               "Failed to decline friend request because user not found. Please try again later."
    end

    test "remove_friendship success", %{users: [current_user, requested_user | _empty] = users} do
      %{current_user: current_user} = login_user(current_user)
      %{current_user: requested_user} = login_user(requested_user)
      [{requested_user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, requested_user.uuid)

      Friendships.create_friendships(current_user, requested_user)
      Friendships.update_friendship(current_user, requested_user)

      Task.async(fn ->
        Process.register(
          self(),
          :"remove_friendship_#{requested_user.uuid}_to_#{current_user.uuid}"
        )

        send(requested_user_pid, {:remove_friendship, [current_user]})

        receive do
          {:ok, friendship} ->
            assert capture_log(fn ->
                     Logger.info(
                       "Friendship removal between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
                     )
                   end) =~
                     "Friendship removal between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}"
        end
      end)
      |> Task.await()

      assert Repo.all(
               Ecto.Query.from(friendship in Friendship, where: friendship.accepted == true)
             )
             |> Enum.count() == 0

      assert current_user |> Repo.preload(:friends) |> Map.get(:friends) == []
      assert requested_user |> Repo.preload(:friends) |> Map.get(:friends) == []
    end
  end

  test "remove_friendship failure", %{users: [current_user, requested_user | _empty] = users} do
    %{current_user: current_user} = login_user(current_user)
    %{current_user: requested_user} = login_user(requested_user)
    [{current_user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, current_user.uuid)
    invalid_requested_user = %User{requested_user | uuid: Ecto.UUID.generate()}

    error =
      Task.async(fn ->
        Process.register(
          self(),
          :"remove_friendship_#{current_user.uuid}_to_#{invalid_requested_user.uuid}"
        )

        send(current_user_pid, {:remove_friendship, [invalid_requested_user]})

        receive do
          {:error, error_message} ->
            assert capture_log(fn ->
                     Logger.error(
                       "Remove friendship error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                         error_message
                     )
                   end) =~
                     "Remove friendship error between #{current_user.uuid}: #{current_user.username} and #{requested_user.uuid}: #{requested_user.username}, reason -> " <>
                       error_message

            error_message
        end
      end)
      |> Task.await()

    assert Repo.all(Ecto.Query.from(friendship in Friendship, where: friendship.pending == true)) ==
             []

    assert Repo.all(Ecto.Query.from(friendship in Friendship, where: friendship.accepted == true)) ==
             []

    assert error ==
             "Failed to remove friend request because user not found. Please try again later."
  end

  test "terminate", %{users: [current_user, requested_user | _empty] = users} do
    %{current_user: current_user} = login_user(current_user)
    [{current_user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, current_user.uuid)

    send(current_user_pid, {:stop_user, []})

    assert capture_log(fn ->
             Logger.info("Stopping user -> #{current_user.uuid}: #{current_user.username}")
           end) =~
             "Stopping user -> #{current_user.uuid}: #{current_user.username}"
  end
end
