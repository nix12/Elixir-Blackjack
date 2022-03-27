defmodule Blackjack.Core.Server do
  import Ecto.Changeset

  defstruct [
    :server_name,
    :user_uuid,
    :inserted_at,
    :updated_at,
    table_count: 0,
    player_count: 0,
    lock_version: 1
  ]

  def change_request(%{} = server, params \\ %{}) do
    types = %{
      server_name: :string,
      user_uuid: :string,
      table_count: :integer,
      player_count: :integer,
      lock_version: :integer,
      inserted_at: :utc_datetime,
      updated_at: :utc_datetime
    }

    {server, types}
    |> cast(params, Map.keys(types))
    |> optimistic_lock(:lock_version)
    |> validate_required([:server_name, :user_uuid])
    |> unique_constraint(:server_name, name: :servers_server_name_index)
  end

  def insert(%{} = record) do
    changeset = change_request(record)

    case changeset.valid? do
      true ->
        Blackjack.Repo.insert_all("servers", [changeset |> apply_changes()],
          returning: [
            :server_name,
            :user_uuid,
            :inserted_at,
            :updated_at,
            :table_count,
            :player_count
          ]
        )

      _ ->
        {:error, %{changeset | action: :insert}}
    end
  end
end
