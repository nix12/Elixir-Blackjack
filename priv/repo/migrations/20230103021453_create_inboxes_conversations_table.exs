defmodule Blackjack.Repo.Migrations.CreateInboxesConversationsTable do
  use Ecto.Migration

  def change do
    create table(:inboxes_conversations) do
      add(:current_user_inbox_id, references(:inboxes))
      add(:conversation_id, references(:conversations))
    end

    create(index(:inboxes_conversations, [:current_user_inbox_id]))
    create(index(:inboxes_conversations, [:conversation_id]))
  end
end
