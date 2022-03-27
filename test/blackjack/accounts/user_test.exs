defmodule Blackjack.Accounts.UserTest do
  use Blackjack.RepoCase, async: true

  alias Blackjack.Accounts.User

  describe "User" do
    test "change_request valid" do
      user_params = %{
        username: "username",
        password_hash: "password",
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }

      {:ok, changeset} = User.insert(user_params)

      assert %{uuid: _, username: _, password_hash: _, inserted_at: _, updated_at: _} = changeset
    end

    test "change_request invalid" do
      user_params = %{username: "", password_hash: ""}
      {:error, changeset} = User.insert(user_params)

      refute changeset.valid?
    end

    test "validates required" do
      user_params = %{username: "", password_hash: ""}
      {:error, changeset} = User.insert(user_params)

      refute changeset.valid?
    end

    test "validates uniqueness" do
      build(:custom_user, username: "username") |> User.insert()

      user_params = %{
        username: "username",
        password_hash: "password",
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }

      {:error, changeset} = User.insert(user_params)

      assert changeset == "This username is already taken."
    end
  end
end
