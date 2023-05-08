defmodule Blackjack.Repo.Migrations.AddUserToInboxes do
  use Ecto.Migration

  def change do
    alter table(:inboxes) do
      add(:user_id, references(:users, column: :id, type: :binary_id))
    end

    create unique_index(:inboxes, [:user_id])
  end
end
