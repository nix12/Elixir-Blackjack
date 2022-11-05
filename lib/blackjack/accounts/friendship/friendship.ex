defmodule Blackjack.Accounts.Friendship do
  @moduledoc """
    Friendship model.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Blackjack.Repo
  alias Blackjack.Accounts.UserQuery

  @derive {Jason.Encoder, only: [:user_uuid, :friend_uuid, :accepted, :pending]}

  schema "friendships" do
    field(:user_uuid, :binary_id)
    field(:friend_uuid, :binary_id)
    field(:accepted, :boolean, default: false)
    field(:pending, :boolean, default: true)
    timestamps()
  end

  def changeset(friendship, params) do
    friendship
    |> cast(params, [:user_uuid, :friend_uuid, :pending])
    |> validate_required([:user_uuid, :friend_uuid])
    |> check_uuids_existence([:user_uuid, :friend_uuid])
    |> unique_constraint(
      [:user_uuid, :friend_uuid],
      name: :friendships_user_uuid_friend_uuid_index
    )
    |> unique_constraint(
      [:friend_uuid, :user_uuid],
      name: :friendships_friend_uuid_user_uuid_index
    )
  end

  @doc """
    Verifies that a uuid exists in the fields user_uuid and friend_uuid.
    If existence? returns false at any point, a error changeset will be
    returned.
  """
  @spec check_uuids_existence(Ecto.Changeset.t(), maybe_improper_list()) :: Ecto.Changeset.t()
  def check_uuids_existence(changeset, fields) when is_list(fields) do
    if Enum.all?(fields, &existence?(changeset, &1)) do
      changeset
    else
      add_error(
        changeset,
        :friendship,
        "One of these fields UUID does not exist: #{inspect(fields)}"
      )
    end
  end

  @doc """
    Checks for the existence of a uuid in a changeset fields, specifically the
    user_uuid and friend_uuid fields.
  """
  @spec existence?(Ecto.Changeset.t(), atom()) :: boolean()
  def existence?(changeset, field) do
    case get_field(changeset, field) |> UserQuery.find_by_uuid() |> Repo.one() do
      nil ->
        false

      _ ->
        true
    end
  end
end
