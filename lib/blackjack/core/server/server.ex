defmodule Blackjack.Core.Server do
  @moduledoc """
    Server model.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Blackjack.Accounts.User

  @derive {Jason.Encoder,
           only: [
             :server_name,
             :user_id,
             :table_count,
             :player_count,
             :inserted_at,
             :updated_at
           ]}

  schema "servers" do
    field(:server_name, :string)
    field(:table_count, :integer, default: 0)
    field(:player_count, :integer, default: 0)
    field(:lock_version, :integer, default: 1)

    belongs_to(:user, User, foreign_key: :user_id, type: :binary)

    timestamps()
  end

  def changeset(server, params) do
    server
    |> cast(params, [:server_name, :user_id])
    |> optimistic_lock(:lock_version)
    |> validate_required([:server_name, :user_id])
    |> unique_constraint(:server_name)
  end
end
