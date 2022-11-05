defmodule Blackjack.Accounts.FriendshipTest do
  use Blackjack.RepoCase, async: true

  alias Blackjack.Accounts.Friendship

  setup do
    current_user = build(:user) |> set_password("password") |> insert()
    requested_user = build(:user) |> set_password("password") |> insert()

    %{current_user: current_user, requested_user: requested_user}
  end

  describe "Friendship" do
    test "insert valid friendship", %{current_user: current_user, requested_user: requested_user} do
      changeset1 =
        Friendship.changeset(%Friendship{}, %{
          user_uuid: current_user.uuid,
          friend_uuid: requested_user.uuid
        })

      changeset2 =
        Friendship.changeset(%Friendship{}, %{
          user_uuid: requested_user.uuid,
          friend_uuid: current_user.uuid
        })

      assert {:ok, new_friendship} = Repo.insert(changeset1)
      assert {:ok, inverse_friendship} = Repo.insert(changeset2)

      {:error, changeset} = Repo.insert(changeset1)

      assert changeset.errors == [
               user_uuid:
                 {"has already been taken",
                  [
                    constraint: :unique,
                    constraint_name: "friendships_user_uuid_friend_uuid_index"
                  ]}
             ]

      refute changeset.valid?
    end

    test "insert invalid friendship where friend_uuid does not exist", %{
      current_user: current_user
    } do
      changeset =
        Friendship.changeset(%Friendship{}, %{
          user_uuid: current_user.uuid,
          friend_uuid: Ecto.UUID.generate()
        })

      assert {:error, changeset} = Repo.insert(changeset)

      assert changeset.errors == [
               friendship:
                 {"One of these fields UUID does not exist: [:user_uuid, :friend_uuid]", []}
             ]

      refute changeset.valid?
    end
  end

  describe "functions" do
    test "check_uuids_existences valid ", %{
      current_user: current_user,
      requested_user: requested_user
    } do
      changeset =
        Friendship.changeset(%Friendship{}, %{
          user_uuid: current_user.uuid,
          friend_uuid: requested_user.uuid
        })

      changeset = Friendship.check_uuids_existence(changeset, [:user_uuid, :friend_uuid])

      assert changeset.valid?
    end

    test "check_uuids_existences invalid", %{
      current_user: current_user,
      requested_user: requested_user
    } do
      changeset =
        Friendship.changeset(%Friendship{}, %{
          user_uuid: current_user.uuid,
          friend_uuid: Ecto.UUID.generate()
        })

      changeset = Friendship.check_uuids_existence(changeset, [:user_uuid, :friend_uuid])

      refute changeset.valid?
    end

    test "existence? valid", %{current_user: current_user, requested_user: requested_user} do
      changeset =
        Friendship.changeset(%Friendship{}, %{
          user_uuid: current_user.uuid,
          friend_uuid: requested_user.uuid
        })

      assert Friendship.existence?(changeset, :user_uuid)
      assert Friendship.existence?(changeset, :friend_uuid)
    end

    test "existence? invalid", %{current_user: current_user, requested_user: requested_user} do
      changeset =
        Friendship.changeset(%Friendship{}, %{
          user_uuid: current_user.uuid,
          friend_uuid: Ecto.UUID.generate()
        })

      assert Friendship.existence?(changeset, :user_uuid)
      refute Friendship.existence?(changeset, :friend_uuid)
    end
  end
end
