defmodule Blackjack.Accounts.User do
  @moduledoc """
    User model
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Bcrypt

  alias Blackjack.Core.Server
  alias Blackjack.Accounts.{User, Friendship, Inbox}

  @derive {Jason.Encoder,
           only: [
             :uuid,
             :email,
             :username,
             :password_hash,
             :inserted_at,
             :updated_at
           ]}
  @primary_key {:uuid, Ecto.UUID, autogenerate: true}

  schema "users" do
    field(:email, :string)
    field(:username, :string)
    field(:password_hash, :string)
    field(:error, :string, virtual: true, default: nil)

    has_one(:server, Server, foreign_key: :user_uuid, defaults: nil)
    has_one(:inbox, Inbox, foreign_key: :user_uuid)

    many_to_many(:friends, User,
      join_through: Friendship,
      join_keys: [user_uuid: :uuid, friend_uuid: :uuid]
    )

    many_to_many(:received_friends, User,
      join_through: Friendship,
      join_keys: [friend_uuid: :uuid, user_uuid: :uuid]
    )

    timestamps()
  end

  def changeset(user, params) do
    user
    |> cast(params, [:email, :username, :password_hash])
    |> validate_required([:email, :username, :password_hash])
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-+']+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/,
      message: "is invalid"
    )
    |> unique_constraint(:email, name: :users_email_index)
    |> unique_constraint(:username, name: :users_username_index)
    |> put_pass_hash
  end

  @spec put_pass_hash(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp put_pass_hash(
         %Ecto.Changeset{valid?: true, changes: %{password_hash: password}} = changeset
       ) do
    change(changeset, add_hash(password))
  end

  defp put_pass_hash(changeset), do: changeset
end
