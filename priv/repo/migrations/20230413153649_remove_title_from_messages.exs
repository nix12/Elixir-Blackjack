defmodule Blackjack.Repo.Migrations.RemoveTitleFromMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      remove :title
    end
  end
end
