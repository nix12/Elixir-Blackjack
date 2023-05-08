defmodule Blackjack.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Blackjack.Repo

  alias Blackjack.Accounts.{User, Friendship}
  alias Blackjack.Accounts.Inbox.Inbox
  alias Blackjack.Core.Server

  def user_factory do
    %User{
      email: Faker.Internet.email(),
      username: Faker.Internet.user_name(),
      password_hash: "password"
    }
  end

  def friendship_factory do
    %Friendship{}
  end

  def inbox_factory do
    %Inbox{}
  end

  def server_factory do
    %Server{server_name: sequence(:server_name, &"test_server-#{&1}")}
  end

  def with_inbox(%User{} = user) do
    insert(:inbox, user: user)

    user
  end

  def set_password(user, password) when user |> is_map() do
    hashed_password = Bcrypt.hash_pwd_salt(password)

    %{user | password_hash: hashed_password}
  end

  def set_password(users, password) when users |> is_list() do
    hashed_password = Bcrypt.hash_pwd_salt(password)

    for user <- users, do: %{user | password_hash: hashed_password}
  end

  def insert_each(users, opts \\ []) do
    for user <- users do
      case opts do
        [] ->
          insert(user)

        _ ->
          [full_user] =
            for opt <- opts do
              user |> insert() |> then(&apply(__MODULE__, opt, [&1]))
            end

          full_user
      end
    end
  end
end
