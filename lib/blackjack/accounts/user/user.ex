defmodule Blackjack.Accounts.User do
  use Ecto.Schema

  import Ecto.Changeset
  import Bcrypt

  # alias Blackjack.Core.Server

  @derive {Jason.Encoder, only: [:uuid, :username, :password_hash, :inserted_at, :updated_at]}
  @primary_key {:uuid, Ecto.UUID, autogenerate: true}

  schema "users" do
    field(:username, :string)
    field(:password_hash, :string)

    # has_one(:server, Server, foreign_key: :user_uuid)

    timestamps()
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:username, :password_hash])
    |> validate_required([:username, :password_hash])
    |> unique_constraint([:username, :uuid], name: :users_username_index)
    |> put_pass_hash
  end

  defp put_pass_hash(
         %Ecto.Changeset{valid?: true, changes: %{password_hash: password}} = changeset
       ) do
    change(changeset, add_hash(password))
  end

  defp put_pass_hash(changeset), do: changeset
end
