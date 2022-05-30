defmodule Blackjack.Accounts.UserTest do
  use Blackjack.RepoCase, async: true

  alias Blackjack.Repo
  alias Blackjack.Accounts.User

  describe "User" do
    test "insert valid user" do
      changeset =
        User.changeset(%User{}, %{
          username: "username0",
          password_hash: "password"
        })

      {:ok, changeset} = Repo.insert(changeset)

      assert %{uuid: _, username: _, password_hash: _, inserted_at: _, updated_at: _} = changeset
    end

    test "insert invalid user" do
      changeset = User.changeset(%User{}, %{username: "", password_hash: ""})
      {:error, changeset} = Repo.insert(changeset)

      refute changeset.valid?
    end

    test "validates required" do
      changeset = User.changeset(%User{}, %{username: "", password_hash: ""})
      {:error, changeset} = Repo.insert(changeset)

      refute changeset.valid?
    end

    test "validates uniqueness" do
      user = build(:user) |> set_password("password") |> insert()

      changeset =
        User.changeset(%User{}, %{
          username: user.username,
          password_hash: "password"
        })

      {:error, changeset} = Repo.insert(changeset)

      [{field, {error, _constraints}}] = changeset.errors
      assert "#{field} #{error}." == "username has already been taken."
    end
  end
end
