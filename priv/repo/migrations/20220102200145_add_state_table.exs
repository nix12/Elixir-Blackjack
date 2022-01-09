defmodule Blackjack.Repo.Migrations.AddStateTable do
  use Ecto.Migration

  def change do
    create table(:states) do
      add(:server_name, :string)
      add(:data, :string)
      add(:lock_version, :integer)

      timestamps()
    end

    create(unique_index(:states, [:server_name]))
  end
end
