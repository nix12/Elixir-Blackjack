defmodule Blackjack.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add(:uuid, :uuid, primary_key: true)
      add(:username, :string)
      add(:password_hash, :string)

      timestamps()
    end

    create(unique_index(:users, [:uuid]))
    create(unique_index(:users, [:username]))
  end
end
