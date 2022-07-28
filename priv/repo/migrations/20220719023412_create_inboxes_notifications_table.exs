defmodule Blackjack.Repo.Migrations.CreateInboxesNotificationsTable do
  use Ecto.Migration

  def change do
    create table(:inboxes_notifications) do
      add(:inbox_id, references(:inboxes, on_delete: :delete_all))
      add(:notification_id, references(:notifications, on_delete: :delete_all))
    end

    create index(:inboxes_notifications, [:inbox_id])
    create index(:inboxes_notifications, [:notification_id])
  end
end
