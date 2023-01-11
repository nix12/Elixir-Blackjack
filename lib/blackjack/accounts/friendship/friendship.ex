defmodule Blackjack.Accounts.Friendship do
  @moduledoc """
    Friendship model.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Blackjack.Repo
  alias Blackjack.Accounts.UserQuery

  @derive {Jason.Encoder, only: [:user_id, :friend_id, :accepted, :pending]}

  schema "friendships" do
    field(:user_id, :binary_id)
    field(:friend_id, :binary_id)
    field(:accepted, :boolean, default: false)
    field(:pending, :boolean, default: true)

    timestamps()
  end

  def changeset(friendship, params) do
    friendship
    |> cast(params, [:user_id, :friend_id, :pending, :accepted])
    |> validate_required([:user_id, :friend_id])
    |> check_ids_existence([:user_id, :friend_id])
    |> unique_constraint(
      [:user_id, :friend_id],
      name: :friendships_user_id_friend_id_index
    )
    |> unique_constraint(
      [:friend_id, :user_id],
      name: :friendships_friend_id_user_id_index
    )
  end

  @doc """
    Verifies that a id exists in the fields user_id and friend_id.
    If existence? returns false at any point, a error changeset will be
    returned.
  """
  @spec check_ids_existence(Ecto.Changeset.t(), maybe_improper_list()) :: Ecto.Changeset.t()
  def check_ids_existence(changeset, fields) when is_list(fields) do
    if Enum.all?(fields, &existence?(changeset, &1)) do
      changeset
    else
      add_error(
        changeset,
        :friendship,
        "One of these fields id does not exist: #{inspect(fields)}"
      )
    end
  end

  @doc """
    Checks for the existence of a id in a changeset fields, specifically the
    user_id and friend_id fields.
  """
  @spec existence?(Ecto.Changeset.t(), atom()) :: boolean()
  def existence?(changeset, field) do
    case get_field(changeset, field) |> UserQuery.find_by_id() |> Repo.one() do
      nil ->
        false

      _ ->
        true
    end
  end
end
