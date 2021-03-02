defmodule Blackjack.Accounts.User do
  use Ecto.Schema

  import Ecto.Changeset
  import Bcrypt

  @derive {Jason.Encoder, only: [:username]}

  schema "users" do
    field(:username, :string)
    field(:password_hash, :string)

    timestamps()
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:username, :password_hash])
    |> validate_required([:username, :password_hash])
    |> unique_constraint(:username)
    |> put_pass_hash
  end

  defp put_pass_hash(
         %Ecto.Changeset{valid?: true, changes: %{password_hash: password}} = changeset
       ) do
    change(changeset, add_hash(password))
  end

  defp put_pass_hash(changeset), do: changeset
end
