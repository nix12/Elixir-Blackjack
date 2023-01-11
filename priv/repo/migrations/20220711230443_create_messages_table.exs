defmodule Blackjack.Repo.Migrations.CreateMessagesTable do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add(:body, :string)
      add(:conversation_id, references(:conversations))
      add(:user_id, references(:users, column: :id, type: :binary_id))
      add(:read, :boolean, default: false)

      timestamps()
    end
  end
end
