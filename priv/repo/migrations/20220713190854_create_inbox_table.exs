defmodule Blackjack.Repo.Migrations.CreateInboxTable do
  use Ecto.Migration

  def change do
    create table(:inboxes) do
      add(:converstation_id, references(:conversations, on_delete: :delete_all))
      add(:notification_id, references(:notifications, on_delete: :delete_all))
    end
  end
end
