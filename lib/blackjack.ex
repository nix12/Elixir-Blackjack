defmodule Blackjack do
  require Logger

  # Utilities

  def start_gui do
    Supervisor.start_link(
      [
        {Ratatouille.Runtime.Supervisor,
         runtime: [app: BlackjackCLI.App, interval: 100, quit_events: [{:key, 0x1B}]]}
      ],
      strategy: :one_for_one
    )
  end

  def stop_gui do
    Supervisor.stop(Ratatouille.Runtime.Supervisor, :normal)
  end

  def via_tuple(registry, name) do
    {:via, Registry, {registry, name}}
  end

  def via_horde(opts) do
    {:via, Horde.Registry, opts}
  end

  def format_name(name) do
    name
    |> String.trim()
    |> String.replace(" ", "_")
    |> String.to_atom()
  end

  def unformat_name(name) do
    name
    |> String.trim()
    |> String.replace("_", " ", global: true)
  end

  def lookup(registry, name) do
    [{pid, _}] = Registry.lookup(registry, name)
    pid
  end

  def name(registry, pid) do
    Registry.keys(registry, pid) |> Enum.at(0)
  end

  @spec blank?(charlist() | nil) :: boolean()
  def blank?(str_or_nil) do
    case str_or_nil do
      "" -> true
      nil -> true
      _ -> false
    end
  end

  # Routes
  def login_path(user_params) do
    # :httpc.request(
    #   :post,
    #   {'http://localhost:#{Application.get_env(:blackjack, :port)}/login', [], 'application/json',
    #    Jason.encode!(user_params)},
    #   [],
    #   []
    # )

    HTTPoison.post(
      "http://localhost:#{Application.get_env(:blackjack, :port)}/login",
      Jason.encode!(user_params),
      [{"Content-Type", "application/json"}]
    )
  end
end
