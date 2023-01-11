defmodule Blackjack.Core.ServerQuery do
  @moduledoc """
    Queries for servers.
  """
  import Ecto.Query, only: [from: 2]

  alias Blackjack.Core.Server

  def query_server(server_name) do
    from(server in Server,
      select: [
        :id,
        :player_count,
        :server_name,
        :table_count,
        :user_id,
        :inserted_at,
        :updated_at
      ],
      where: [server_name: ^server_name]
    )
  end

  def query_servers() do
    from(server in Server, select: server)
  end

  # def update_by_server_name(server_name) do
  #   from(s in Server,
  #     select: [:player_count, :server_name, :table_count, :user_id, :inserted_at, :updated_at],
  #     where: [server_name: ^server_name],
  #     update: [set: [player_count: ^player_count(server_name)]]
  #   )
  # end
end
