defmodule Blackjack.Repo.Migrations.AddRecipientInboxToInboxesConversations do
  use Ecto.Migration

  def change do
    alter table(:inboxes_conversations) do
      add(:recipient_inbox_id, references(:inboxes))
    end

    create(index(:inboxes_conversations, [:recipient_inbox_id]))
  end
end
