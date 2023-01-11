defmodule Blackjack.Repo.Migrations.AddTitleToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add(:title, :string, null: true)
    end
  end
end
