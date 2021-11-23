defmodule Blackjack.Core.Server do
  use Ecto.Schema

  import Ecto.Changeset

  alias Blackjack.Accounts.User

  @derive {Jason.Encoder, only: [:server_name, :user_uuid, :table_count, :player_count]}

  schema "servers" do
    field(:server_name, :string)
    field(:table_count, :integer, default: 0)
    field(:player_count, :integer, default: 0)
    field(:lock_version, :integer, default: 1)

    belongs_to(:user, User, foreign_key: :user_uuid, references: :uuid, type: :string)

    timestamps()
  end

  def changeset(server, params \\ %{}) do
    server
    |> cast(params, [:server_name, :table_count, :player_count])
    |> optimistic_lock(:lock_version)
    |> validate_required([:server_name])
    |> unique_constraint(:server_name)
  end
end
