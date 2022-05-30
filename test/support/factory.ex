defmodule Blackjack.Factory do
  use ExMachina.Ecto, repo: Blackjack.Repo

  alias Blackjack.Accounts.User
  alias Blackjack.Core.Server

  def user_factory do
    %User{username: sequence("username"), password_hash: "password"}
  end

  def server_factory do
    %Server{server_name: sequence(:server_name, &"test_server-#{&1}")}
  end

  def set_password(user, password) do
    hashed_password = Bcrypt.hash_pwd_salt(password)

    %{user | password_hash: hashed_password}
  end
end
