defmodule Blackjack.Repo.Migrations.CreateConversationsTable do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add(:user_id, references(:users, column: :id, type: :binary_id))
      add(:recipient_id, references(:users, column: :id, type: :binary_id))

      timestamps()
    end

    create index(:conversations, [:user_id])
    create index(:conversations, [:recipient_id])

    create unique_index(
      :conversations,
      [:user_id, :recipient_id],
      name: :conversations_user_id_recipient_id_index
    )

    create unique_index(
      :conversations,
      [:recipient_id, :user_id],
      name: :conversations_recipient_id_user_id_index
    )
  end
end
