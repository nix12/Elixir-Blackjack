defmodule Blackjack.Repo.Migrations.Add_User_To_Server do
  use Ecto.Migration

  def change do
    alter table(:servers) do
      add(:user_id, references(:users, column: :id, type: :binary_id, on_delete: :delete_all))
    end
  end
end
