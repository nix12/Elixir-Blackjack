defmodule Blackjack.Repo.Migrations.AddReferencesToNotifications do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      modify(:recipient_inbox_id, references(:inboxes))
    end
  end
end
