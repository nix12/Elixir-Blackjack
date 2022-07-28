defmodule Blackjack.Accounts.UserQuery do
  import Ecto.Query

  alias Blackjack.Accounts.User

  def find_by_username(username) do
    from(
      user in User,
      where: user.username == ^username,
      select: %{
        uuid: user.uuid,
        username: user.username,
        password_hash: user.password_hash,
        inserted_at: user.inserted_at,
        updated_at: user.updated_at
      }
    )
  end

  def find_by_uuid(uuid) do
    from(user in User,
      where: user.uuid == ^uuid,
      select: %{
        uuid: user.uuid,
        username: user.username,
        password_hash: user.password_hash,
        inserted_at: user.inserted_at,
        updated_at: user.updated_at
      }
    )
  end
end
