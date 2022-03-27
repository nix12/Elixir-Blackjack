defmodule Blackjack.Factory do
  use ExMachina

  def custom_user_factory(attrs) do
    user = %{
      username: "username",
      password_hash: "password",
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

    user
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def custom_server_factory(attrs) do
    server = %{
      server_name: "test",
      table_count: 0,
      player_count: 0,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

    server
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end
end
