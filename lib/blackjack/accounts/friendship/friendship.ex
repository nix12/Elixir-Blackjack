defmodule Blackjack.Accounts.Friendship do
  use Ecto.Schema

  import Ecto.Changeset

  alias Blackjack.Repo
  alias Blackjack.Accounts.UserQuery

  @derive {Jason.Encoder, only: [:user_uuid, :friend_uuid, :pending]}

  schema "friendships" do
    field(:user_uuid, :binary_id)
    field(:friend_uuid, :binary_id)
    field(:pending, :boolean, default: true)
    field(:error, :string, virtual: true, default: nil)

    timestamps()
  end

  def changeset(friendship, params \\ %{}) do
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

  def check_uuids_existence(changeset, fields) when is_list(fields) do
    if Enum.all?(fields, &existence?(changeset, &1)) do
      changeset
    else
      add_error(
        changeset,
        hd(fields),
        "One of these fields UUID does not exist: #{inspect(fields)}"
      )
    end
  end

  def existence?(changeset, field) do
    value = get_field(changeset, field)

    case value do
      nil ->
        false

      _ ->
        value
        |> UserQuery.find_by_uuid()
        |> Repo.exists?()
    end
  end
end
