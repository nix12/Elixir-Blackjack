defmodule Blackjack.Factory do
  use ExMachina.Ecto, repo: Blackjack.Repo

  alias Blackjack.Accounts.User
  alias Blackjack.Core.Server

  def user_factory do
    %User{
      email: Faker.Internet.email(),
      username: Faker.Internet.user_name(),
      password_hash: "password"
    }
  end

  def server_factory do
    %Server{server_name: sequence(:server_name, &"test_server-#{&1}")}
  end

  def set_password(user, password) when user |> is_map() do
    hashed_password = Bcrypt.hash_pwd_salt(password)

    %{user | password_hash: hashed_password}
  end

  def set_password(users, password) when users |> is_list() do
    hashed_password = Bcrypt.hash_pwd_salt(password)

    for user <- users, do: %{user | password_hash: hashed_password}
  end

  def insert_each(users) do
    for user <- users, do: insert(user)
  end
end
