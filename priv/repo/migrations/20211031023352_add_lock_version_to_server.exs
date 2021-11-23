defmodule Blackjack.Repo.Migrations.AddLockVersionToServer do
  use Ecto.Migration

  def change do
    alter table(:servers) do
      add :lock_version, :integer, default: 1
    end
  end
end
