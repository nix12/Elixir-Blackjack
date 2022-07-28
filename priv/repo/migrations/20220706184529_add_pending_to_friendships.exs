defmodule Blackjack.Repo.Migrations.AddPendingToFriendships do
  use Ecto.Migration

  def change do
    alter table(:friendships) do
      add(:pending, :boolean, default: true)
    end
  end
end
