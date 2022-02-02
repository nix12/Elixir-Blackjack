defmodule Blackjack.Core.StateManager do
  require Logger

  import Ecto.Changeset

  defstruct [:server_name, :data, :inserted_at, :updated_at, lock_version: 1]

  def prepare(%{} = state, params \\ %{}) do
    types = %{
      # Change to lookup through association(schemaless)
      server_name: :string,
      data: :string,
      inserted_at: :utc_datetime,
      updated_at: :utc_datetime
    }

    {state, types}
    |> cast(params, Map.keys(types))
    |> optimistic_lock(:lock_version)
    |> validate_required([:data])
  end

  def insert(%__MODULE__{} = record) do
    changeset = prepare(record)

    case changeset.valid? do
      true ->
        Blackjack.Repo.insert_all("states", [changeset |> apply_changes() |> Map.from_struct()],
          on_conflict: {:replace, [:data]},
          conflict_target: :server_name
        )

      _ ->
        Logger.info("ERROR")
        {:error, %{changeset | action: :insert}}
    end
  end
end
