defmodule Blackjack.Repo.Migrations.AddInboxIdToConversations do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :inbox_id, references(:inboxes, on_delete: :delete_all)
    end

    create index(:conversations, [:inbox_id])
  end
end
