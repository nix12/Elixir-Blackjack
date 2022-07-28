defmodule Blackjack.Repo.Migrations.AddAcceptedToFriendships do
  use Ecto.Migration

  def change do
    alter table(:friendships) do
      add(:accepted, :boolean, default: false)
    end
  end
end
