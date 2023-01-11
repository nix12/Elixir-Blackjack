defmodule Blackjack.Repo.Migrations.AddUserToInboxes do
  use Ecto.Migration

  def change do
    alter table(:inboxes) do
      add(:user_id, references(:users, column: :id, type: :binary_id, on_delete: :delete_all))
    end

    create unique_index(:inboxes, [:user_id])
  end
end
