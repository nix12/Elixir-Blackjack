defmodule Blackjack.Repo.Migrations.CreateServersTable do
  use Ecto.Migration

  def change do
    create table(:servers) do
      add(:server_name, :string)
      add(:table_count, :integer, default: 0)
      add(:player_count, :integer, default: 0)

      timestamps()
    end

    create(unique_index(:servers, [:server_name]))
  end
end
