defmodule Blackjack.Repo.Migrations.AddUserUuidToInboxes do
  use Ecto.Migration

  def change do
    alter table(:inboxes) do
      add(:user_uuid, references(:users, column: :uuid, type: :binary_id, on_delete: :delete_all))
    end

    create unique_index(:inboxes, [:user_uuid])
  end
end
