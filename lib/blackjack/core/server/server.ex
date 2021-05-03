defmodule Blackjack.Core.Server do
  use Ecto.Schema

  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:server_name]}

  schema "servers" do
    field(:server_name, :string)
    field(:table_count, :integer, default: 0)
    field(:player_count, :integer, default: 0)

    timestamps()
  end

  def changeset(server, params \\ %{}) do
    server
    |> cast(params, [:server_name, :table_count, :player_count])
    |> validate_required([:server_name])
    |> unique_constraint(:server_name)
  end
end
