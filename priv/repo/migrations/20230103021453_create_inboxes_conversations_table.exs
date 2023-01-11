defmodule Blackjack.Repo.Migrations.CreateInboxesConversationsTable do
  use Ecto.Migration

  def change do
    create table(:inboxes_conversations) do
      add(:inbox_id, references(:inboxes, on_delete: :delete_all))
      add(:conversation_id, references(:conversations, on_delete: :delete_all))
    end

    create index(:inboxes_conversations, [:inbox_id])
    create index(:inboxes_conversations, [:conversation_id])
  end
end
