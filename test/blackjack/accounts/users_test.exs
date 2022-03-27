defmodule Blackjack.Accounts.UsersTest do
  use Blackjack.RepoCase, async: false

  import Ecto.Query, only: [from: 2]

  alias Blackjack.Accounts.Supervisor, as: AccountsSupervisor
  alias Blackjack.Accounts.{User, Users}
  alias Blackjack.Core.Supervisor, as: CoreSupervisor
  alias Blackjack.Core.{Server, Servers}

  setup do
    build(:custom_user) |> User.insert()

    :ok
  end

  describe "Users Account" do
    test "init/1" do
      {:ok, user_account} = Users.init(%{username: "username", password_hash: "password"})

      assert %{uuid: _, username: "username", password_hash: _, inserted_at: _, updated_at: _} =
               user_account
    end

    test "get_user" do
      state = %{
        uuid: "uuid",
        username: "username",
        password_hash: "password",
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }

      {:reply, response, new_state} = Users.handle_call({:get_user}, nil, state)

      assert response == new_state
    end

    test "sync_server" do
      login_params = %{
        username: "username",
        password_hash: "password"
      }

      AccountsSupervisor.start_child(login_params)
      user = Users.get_user("username")
      user_uuid = Ecto.UUID.load!(user.uuid)
      build(:custom_server, user_uuid: user_uuid) |> Server.insert()
      CoreSupervisor.start_child({:start, "test", "username"})

      {:reply, response, new_state} =
        Users.handle_call(
          {:sync_server, [BlackjackCli.get_server("test")]},
          nil,
          Servers.get_server("test")
        )

      assert response.server_name == "test"
      assert response == new_state
    end
  end
end
