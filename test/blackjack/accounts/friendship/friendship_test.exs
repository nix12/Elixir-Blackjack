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
          user_id: current_user.id,
          friend_id: requested_user.id
        })

      changeset2 =
        Friendship.changeset(%Friendship{}, %{
          user_id: requested_user.id,
          friend_id: current_user.id
        })

      assert {:ok, new_friendship} = Repo.insert(changeset1)
      assert {:ok, inverse_friendship} = Repo.insert(changeset2)

      {:error, changeset} = Repo.insert(changeset1)

      assert changeset.errors == [
               user_id:
                 {"has already been taken",
                  [
                    constraint: :unique,
                    constraint_name: "friendships_user_uuid_friend_uuid_index"
                  ]}
             ]

      refute changeset.valid?
    end

    test "insert invalid friendship where friend_id does not exist", %{
      current_user: current_user
    } do
      changeset =
        Friendship.changeset(%Friendship{}, %{
          user_id: current_user.id,
          friend_id: Ecto.UUID.generate()
        })

      assert {:error, changeset} = Repo.insert(changeset)

      assert changeset.errors == [
               friendship: {"One of these fields UUID does not exist: [:user_id, :friend_id]", []}
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
          user_id: current_user.id,
          friend_id: requested_user.id
        })

      changeset = Friendship.check_uuids_existence(changeset, [:user_id, :friend_id])

      assert changeset.valid?
    end

    test "check_uuids_existences invalid", %{
      current_user: current_user,
      requested_user: requested_user
    } do
      changeset =
        Friendship.changeset(%Friendship{}, %{
          user_id: current_user.id,
          friend_id: Ecto.UUID.generate()
        })

      changeset = Friendship.check_uuids_existence(changeset, [:user_id, :friend_id])

      refute changeset.valid?
    end

    test "existence? valid", %{current_user: current_user, requested_user: requested_user} do
      changeset =
        Friendship.changeset(%Friendship{}, %{
          user_id: current_user.id,
          friend_id: requested_user.id
        })

      assert Friendship.existence?(changeset, :user_id)
      assert Friendship.existence?(changeset, :friend_id)
    end

    test "existence? invalid", %{current_user: current_user, requested_user: requested_user} do
      changeset =
        Friendship.changeset(%Friendship{}, %{
          user_id: current_user.id,
          friend_id: Ecto.UUID.generate()
        })

      assert Friendship.existence?(changeset, :user_id)
      refute Friendship.existence?(changeset, :friend_id)
    end
  end
end
