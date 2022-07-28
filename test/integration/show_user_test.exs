defmodule ShowUserTest do
  use Blackjack.RepoCase, async: false
  use Plug.Test

  alias Blackjack.Repo
  alias Blackjack.Accounts.User
  alias Blackjack.Accounts.Authentication.Guardian

  setup do
    user1 = build(:user) |> set_password("password") |> insert()
    user2 = build(:user) |> set_password("password") |> insert()

    %{user1: user1, user2: user2}
  end

  describe "GET /:uuid" do
    test "SUCCESS", %{user1: user1, user2: user2} do
      {:ok, token, _claims} = Guardian.encode_and_sign(user1)

      %HTTPoison.Response{body: body, status_code: status} =
        show_user_path(user2.uuid, {"authorization", "Bearer " <> token})

      %{"user" => viewed_user} = body |> Jason.decode!()

      assert status == 200

      assert viewed_user["email"] == user2.email
      assert viewed_user["username"] == user2.username
      assert viewed_user["uuid"] == user2.uuid
    end

    test "failure!", %{user1: user1, user2: user2} do
      %HTTPoison.Response{body: body, status_code: status} =
        show_user_path(user2.uuid, {"authorization", nil})

      assert body |> Jason.decode!() == %{"message" => "unauthenticated"}
    end
  end
end
