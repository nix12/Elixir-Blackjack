defmodule Blackjack.Repo.Migrations.Add_User_UUID_To_Server do
  use Ecto.Migration

  def change do
    alter table(:servers) do
      add(:user_uuid, :string)
    end
  end
end
