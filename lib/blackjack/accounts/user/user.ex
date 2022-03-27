defmodule Blackjack.Accounts.User do
  import Ecto.Changeset
  import Bcrypt

  # @derive {Jason.Encoder, only: [:uuid, :username, :password_hash, :inserted_at, :updated_at]}
  defstruct [:uuid, :username, :password_hash, :inserted_at, :updated_at]

  defimpl Jason.Encoder, for: Ecto.Changeset do
    def encode(value, opts) do
      Jason.Encode.map(
        Map.take(value, [:uuid, :username, :password_hash, :inserted_at, :updated_at]),
        opts
      )
    end
  end

  def change_request(%{} = user, params \\ %{}) do
    types = %{
      uuid: Ecto.UUID,
      username: :string,
      password_hash: :string,
      inserted_at: :utc_datetime,
      updated_at: :utc_datetime
    }

    {user, types}
    |> cast(params, Map.keys(types))
    |> update_change(:username, &String.downcase/1)
    |> unique_constraint([:username, :uuid], name: :users_username_index)
    |> validate_required([:username, :password_hash])
    |> put_uuid()
    |> put_pass_hash()
  end

  def insert(%{} = record) do
    changeset = change_request(record)

    case insert_user(changeset) do
      {:error, message} ->
        {:errors, message}

      record ->
        {:ok, record}
    end
  end

  defp insert_user(%Ecto.Changeset{valid?: true} = changeset) do
    try do
      Blackjack.Repo.insert_all("users", [changeset |> apply_changes()],
        returning: [:uuid, :username, :password_hash, :inserted_at, :updated_at]
      )
    rescue
      _exception in Postgrex.Error ->
        {:error, "This username is already taken."}
    else
      {_, [value]} ->
        value
    end
  end

  defp put_uuid(%Ecto.Changeset{valid?: true} = changeset) do
    put_change(changeset, :uuid, Ecto.UUID.bingenerate())
  end

  defp put_uuid(changeset), do: changeset

  defp put_pass_hash(%Ecto.Changeset{valid?: true} = changeset) do
    password = get_field(changeset, :password_hash)
    hashed_password = add_hash(password)

    change(changeset, hashed_password)
  end

  defp put_pass_hash(changeset), do: changeset |> IO.inspect(label: "++++++++ HASHED PASS 2")
end
