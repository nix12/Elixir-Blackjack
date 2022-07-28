defmodule Blackjack.Repo.Migrations.CreateConversationsTable do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add(:sender_uuid, references(:users, column: :uuid, type: :binary_id, on_delete: :delete_all))
      add(:recipient_uuid, references(:users, column: :uuid, type: :binary_id, on_delete: :delete_all))

      timestamps()
    end
  end
end
