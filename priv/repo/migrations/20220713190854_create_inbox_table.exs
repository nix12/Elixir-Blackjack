defmodule Blackjack.Repo.Migrations.CreateInboxTable do
  use Ecto.Migration

  def change do
    create table(:inboxes) do
      add(:converstation_id, references(:conversations))
      add(:notification_id, references(:notifications))
    end
  end
end
