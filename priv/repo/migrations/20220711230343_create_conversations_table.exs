defmodule Blackjack.Repo.Migrations.CreateConversationsTable do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add(:current_user_inbox_id, :integer)
      add(:recipient_inbox_id, :integer)

      timestamps()
    end

    create index(:conversations, [:current_user_inbox_id])
    create index(:conversations, [:recipient_inbox_id])

    create unique_index(
      :conversations,
      [:current_user_inbox_id, :recipient_inbox_id],
      name: :conversations_user_inbox_id_recipient_inbox_id_index
    )

    create unique_index(
      :conversations,
      [:recipient_inbox_id, :current_user_inbox_id],
      name: :conversations_recipient_inbox_id_user_inbox_id_index
    )
  end
end
