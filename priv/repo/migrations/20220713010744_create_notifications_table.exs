defmodule Blackjack.Repo.Migrations.CreateNotificationsTable do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add(:body, :string)
      add(:read, :bool)
      add(:user_uuid, references(:users, column: :uuid, type: :binary_id, on_delete: :delete_all))

      timestamps()
    end
  end
end
