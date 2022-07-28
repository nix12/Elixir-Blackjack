defmodule Blackjack.Accounts.UserManagerTest do
  use Blackjack.RepoCase, async: false

  alias Blackjack.Accounts.Supervisor, as: AccountsSupervisor
  alias Blackjack.Accounts.{User, UserManager}

  setup do
    user = build(:user) |> set_password("password") |> insert()

    %{user: user}
  end

  describe "UserManager Account" do
    test "init/1", %{user: user} do
      {:ok, user_account} =
        UserManager.init(%{
          uuid: user.uuid,
          email: user.email,
          username: user.username,
          password_hash: user.password_hash,
          inserted_at: user.inserted_at,
          updated_at: user.updated_at
        })

      assert %{
               uuid: user.uuid,
               email: user.email,
               username: user.username,
               password_hash: user.password_hash,
               inserted_at: user.inserted_at,
               updated_at: user.updated_at
             } ==
               user_account
    end

    test "get_user", %{user: user} do
      {:reply, response, new_state} = UserManager.handle_call({:get_user}, nil, user)

      assert response == new_state
    end

    test "update_user", %{user: user} do
      change_params = %{
        uuid: user.uuid,
        email: Faker.Internet.email(),
        username: Faker.Internet.user_name(),
        password_hash: "newpassword"
      }

      send(self(), {:update_user, change_params})
      assert_received {:update_user, change_params}

      assert user.uuid == change_params.uuid
      refute user.email == change_params.email
      refute user.username == change_params.username
      refute user.password_hash == change_params.password_hash
    end
  end
end
