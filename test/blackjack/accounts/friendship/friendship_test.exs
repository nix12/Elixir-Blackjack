defmodule Blackjack.Accounts.FriendshipTest do
  use Blackjack.RepoCase, async: true

  alias Blackjack.Repo
  alias Blackjack.Accounts.Friendship

  setup do
    user1 = build(:user) |> set_password("password") |> insert()
    user2 = build(:user) |> set_password("password") |> insert()

    %{user1: user1, user2: user2}
  end

  describe "Friendship" do
    test "insert valid friendship", %{user1: user1, user2: user2} do
      changeset1 =
        Friendship.changeset(%Friendship{}, %{user_uuid: user1.uuid, friend_uuid: user2.uuid})

      changeset2 =
        Friendship.changeset(%Friendship{}, %{user_uuid: user2.uuid, friend_uuid: user1.uuid})

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
      user1: user1
    } do
      changeset =
        Friendship.changeset(%Friendship{}, %{
          user_uuid: user1.uuid,
          friend_uuid: Ecto.UUID.generate()
        })

      assert {:error, changeset} = Repo.insert(changeset)

      assert changeset.errors == [
               user_uuid:
                 {"One of these fields UUID does not exist: [:user_uuid, :friend_uuid]", []}
             ]

      refute changeset.valid?
    end

    test "insert invalid friendship where friend_uuid is empty", %{user1: user1} do
      changeset = Friendship.changeset(%Friendship{}, %{user_uuid: user1.uuid, friend_uuid: ""})

      assert {:error, changeset} = Repo.insert(changeset)
      refute changeset.valid?
    end
  end

  describe "functions" do
    test "check_uuids_existences valid ", %{user1: user1, user2: user2} do
      changeset =
        Friendship.changeset(%Friendship{}, %{user_uuid: user1.uuid, friend_uuid: user2.uuid})

      changeset = Friendship.check_uuids_existence(changeset, [:user_uuid, :friend_uuid])

      assert changeset.valid?
    end

    test "check_uuids_existences invalid", %{user1: user1, user2: user2} do
      changeset =
        Friendship.changeset(%Friendship{}, %{
          user_uuid: user1.uuid,
          friend_uuid: Ecto.UUID.generate()
        })

      changeset = Friendship.check_uuids_existence(changeset, [:user_uuid, :friend_uuid])

      refute changeset.valid?
    end

    test "existence? valid", %{user1: user1, user2: user2} do
      changeset =
        Friendship.changeset(%Friendship{}, %{user_uuid: user1.uuid, friend_uuid: user2.uuid})

      assert Friendship.existence?(changeset, :user_uuid)
      assert Friendship.existence?(changeset, :friend_uuid)
    end

    test "existence? invalid", %{user1: user1, user2: user2} do
      changeset =
        Friendship.changeset(%Friendship{}, %{
          user_uuid: user1.uuid,
          friend_uuid: Ecto.UUID.generate()
        })

      assert Friendship.existence?(changeset, :user_uuid)
      refute Friendship.existence?(changeset, :friend_uuid)
    end
  end
end
