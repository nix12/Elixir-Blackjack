defmodule Blackjack.Repo.Migrations.CreateInboxesNotificationsTable do
  use Ecto.Migration

  def change do
    create table(:inboxes_notifications) do
      add(:inbox_id, references(:inboxes))
      add(:notification_id, references(:notifications))
    end

    create(index(:inboxes_notifications, [:inbox_id]))
    create(index(:inboxes_notifications, [:notification_id]))
  end
end
