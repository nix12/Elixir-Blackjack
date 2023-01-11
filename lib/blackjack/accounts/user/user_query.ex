defmodule Blackjack.Accounts.UserQuery do
  @moduledoc """
    Contains user query functions.
  """
  import Ecto.Query, only: [from: 2]

  alias Blackjack.Accounts.User

  @type username :: String.t()
  @type id :: String.t()

  @doc """
    Finds a user by the username.
  """
  @spec find_by_username(username()) :: Ecto.Query.t()
  def find_by_username(username), do: from(user in User, where: user.username == ^username)

  @doc """
    Finds a user by the id.
  """
  @spec find_by_id(id()) :: Ecto.Query.t()
  def find_by_id(id), do: from(user in User, where: user.id == ^id)
end
