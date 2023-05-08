defmodule Blackjack.Repo.Migrations.AddReferencesToConversations do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      modify(:current_user_inbox_id, references(:inboxes))
      modify(:recipient_inbox_id, references(:inboxes))
    end
  end
end
