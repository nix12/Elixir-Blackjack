defmodule Blackjack.Accounts.Users do
  alias Blackjack.Repo
  alias Blackjack.Accounts.UserQuery

  # @enforce_keys [:username, :password_hash]
  # defstruct [:username, :password_hash]

  # def new do
  #   %User{username: nil, password_hash: nil, uuid: nil, inserted_at: nil, updated_at: nil}
  # end

  # def assign_user(username) do
  #   case username |> UserQuery.user_query() |> Repo.one() do
  #     nil ->
  #       {:error, "No user found."}

  #     user ->
  #       {:assign_user, user}
  #   end
  # end
end
