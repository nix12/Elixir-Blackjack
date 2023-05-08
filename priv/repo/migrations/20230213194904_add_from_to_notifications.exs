defmodule Blackjack.Repo.Migrations.AddFromToNotifications do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add(:from, :string, default: "System")
    end
  end
end
