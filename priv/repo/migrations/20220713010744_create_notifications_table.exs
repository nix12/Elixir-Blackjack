defmodule Blackjack.Repo.Migrations.CreateNotificationsTable do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add(:body, :string)
      add(:read, :bool)
      add(:recipient_inbox_id, :integer)

      timestamps()
    end
  end
end
