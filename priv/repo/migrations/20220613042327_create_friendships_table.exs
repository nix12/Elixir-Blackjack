defmodule Blackjack.Repo.Migrations.CreateFriendshipsTable do
  use Ecto.Migration

  def change do
    create table(:friendships) do
      add(:user_uuid, references(:users, column: :uuid, type: :binary_id, on_delete: :delete_all))
      add(:friend_uuid, references(:users, column: :uuid, type: :binary_id, on_delete: :delete_all))

      timestamps()
    end

    create index(:friendships, [:user_uuid])
    create index(:friendships, [:friend_uuid])

    create unique_index(
      :friendships,
      [:user_uuid, :friend_uuid],
      name: :friendships_user_uuid_friend_uuid_index
    )

    create unique_index(
      :friendships,
      [:friend_uuid, :user_uuid],
      name: :friendships_friend_uuid_user_uuid_index
    )
  end
end
