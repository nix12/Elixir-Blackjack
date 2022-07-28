defmodule Blackjack.Repo.Migrations.AddInboxIdToNotifications do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :inbox_id, references(:inboxes, on_delete: :delete_all)
    end

    create index(:notifications, [:inbox_id])
  end
end
