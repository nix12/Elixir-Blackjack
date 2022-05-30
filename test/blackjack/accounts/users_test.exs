defmodule Blackjack.Accounts.UsersTest do
  use Blackjack.RepoCase, async: false

  import Ecto.Query, only: [from: 2]

  alias Blackjack.Accounts.Supervisor, as: AccountsSupervisor
  alias Blackjack.Accounts.{User, AccountsServer}
  alias Blackjack.Core
  alias Blackjack.Core.Supervisor, as: CoreSupervisor
  alias Blackjack.Core.{Server, Servers}

  setup do
    user = build(:user) |> set_password("password") |> insert()

    %{user: user}
  end

  describe "AccountsServer Account" do
    test "init/1", %{user: user} do
      {:ok, user_account} =
        AccountsServer.init(%{username: user.username, password_hash: "password"})

      assert %{
               uuid: user.uuid,
               username: user.username,
               password_hash: user.password_hash,
               inserted_at: user.inserted_at,
               updated_at: user.updated_at
             } ==
               user_account
    end

    test "get_user", %{user: user} do
      state = %{
        username: user.username,
        password_hash: "password"
      }

      {:reply, response, new_state} = AccountsServer.handle_call({:get_user}, nil, state)

      assert response == new_state
    end

    # For updating all connected databases, but will be using single database
    # test "sync_server", %{user: user} do
    #   server = build(:server, user: user) |> insert()
    #   CoreSupervisor.start_child({:start, server.server_name, user.username})

    #   {:reply, response, new_state} =
    #     AccountsServer.handle_call(
    #       {:sync_server, [Core.get_server(server.server_name)]},
    #       nil,
    #       Servers.get_server(server.server_name)
    #     )

    #   assert response.server_name == server.server_name
    #   assert response == new_state
    # end
  end
end
