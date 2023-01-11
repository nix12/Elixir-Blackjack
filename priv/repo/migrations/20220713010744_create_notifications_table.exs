defmodule Blackjack.Repo.Migrations.CreateNotificationsTable do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add(:body, :string)
      add(:read, :bool)
      add(:user_id, references(:users, column: :id, type: :binary_id, on_delete: :delete_all))

      timestamps()
    end
  end
end
