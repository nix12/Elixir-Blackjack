defmodule Blackjack.Repo.Migrations.CreateMessagesTable do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add(:body, :string)
      add(:conversation_id, references(:conversations))
      add(:user_uuid, references(:users, column: :uuid, type: :binary_id))
      add(:read, :boolean, default: false)

      timestamps()
    end

    create unique_index(:messages, [:conversation_id])
    create unique_index(:messages, [:user_uuid])
  end
end
