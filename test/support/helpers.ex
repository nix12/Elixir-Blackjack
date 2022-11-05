defmodule Blackjack.Helpers do
  @moduledoc false
  alias Blackjack.Accounts.Authentication.Guardian

  def state do
    %{input: 0, menu: true, user: nil, screen: :start, token: "", data: []}
  end

  def input(initial_state, module, override \\ %{})

  def input(initial_state, module, override) when override.input |> is_bitstring do
    state = %{initial_state | input: ""}

    for ch <- override.input |> to_charlist do
      module.update(state, {:event, %{ch: ch}})
    end
    |> Enum.reduce(
      state,
      fn map, acc ->
        Map.merge(acc, map, fn _k, _v1, v2 -> v2 end)
      end
    )
  end

  def input(initial_state, module, override) when override.input |> is_integer do
    charlist = override.input
    state = Map.merge(initial_state, %{override | input: 0})

    module.update(state, {:event, %{ch: charlist}})
  end

  # URL

  def update_user_url(user) do
    "http://localhost:#{Application.get_env(:blackjack, :port)}/user/#{user.uuid}/update"
  end

  def show_user_url(user) do
    "http://localhost:#{Application.get_env(:blackjack, :port)}/user/#{user.uuid}"
  end

  def create_friendship_url do
    "http://localhost:" <>
      (Application.get_env(:blackjack, :port) |> to_string()) <> "/friendship/create"
  end

  def accept_friendship_url(user) do
    "http://localhost:" <>
      (Application.get_env(:blackjack, :port) |> to_string()) <>
      "/friendship/" <> user.uuid <> "/accept"
  end

  def decline_friendship_url(user) do
    "http://localhost:" <>
      (Application.get_env(:blackjack, :port) |> to_string()) <>
      "/friendship/" <> user.uuid <> "/decline"
  end

  def destroy_friendship_url(user) do
    "http://localhost:" <>
      (Application.get_env(:blackjack, :port) |> to_string()) <>
      "/friendship/" <> user.uuid <> "/destroy"
  end

  # Requested routes
  def register_path(user_params) do
    HTTPoison.post!(
      "http://localhost:" <>
        (Application.get_env(:blackjack, :port) |> to_string()) <> "/register",
      Jason.encode!(user_params),
      [{"content-type", "application/json"}]
    )
  end

  def login_path(user_params) do
    HTTPoison.post!(
      "http://localhost:" <>
        (Application.get_env(:blackjack, :port) |> to_string()) <> "/login",
      Jason.encode!(user_params),
      [{"content-type", "application/json"}]
    )
  end

  def logout_path(user_token) do
    HTTPoison.delete!(
      "http://localhost:" <>
        (Application.get_env(:blackjack, :port) |> to_string()) <> "/logout",
      [{"authorization", "Bearer " <> user_token}]
    )
  end

  def update_user_path(user, change_params, user_token) do
    HTTPoison.put!(
      "http://localhost:" <>
        (Application.get_env(:blackjack, :port) |> to_string()) <>
        "/user/" <> user.uuid <> "/update",
      Jason.encode!(change_params),
      [{"content-type", "application/json"}, {"authorization", "Bearer " <> user_token}]
    )
  end

  def show_user_path(current_user_header, requested_user_uuid) do
    HTTPoison.get!(
      "http://localhost:" <>
        (Application.get_env(:blackjack, :port) |> to_string()) <>
        "/user/" <> requested_user_uuid,
      [current_user_header]
    )
  end

  def create_friendship_path(friendship_params, auth_header) do
    HTTPoison.post!(
      "http://localhost:" <>
        (Application.get_env(:blackjack, :port) |> to_string()) <> "/friendship/create",
      Jason.encode!(friendship_params),
      [{"content-type", "application/json"}, auth_header]
    )
  end

  # Helpers
  def login_user(user) do
    login_params = %{user: %{email: user.email, password_hash: user.password_hash}}

    %HTTPoison.Response{
      headers: headers,
      status_code: status,
      body: body
    } = login_path(login_params)

    token_or_nil =
      case headers |> token_or_nil() do
        [] ->
          ""

        [token] ->
          token
      end

    {:ok, current_user_or_nl} =
      headers
      |> token_or_nil()
      |> current_user_or_nil()

    %{
      current_user: current_user_or_nl,
      token: token_or_nil,
      info: {status, body |> Jason.decode!()}
    }
  end

  def logout_user(token) do
    %HTTPoison.Response{status_code: status, body: body} = logout_path(token)

    %{status: status, body: body}
  end

  def update_user(user, change_params, current_user_token) do
    %HTTPoison.Response{
      headers: headers,
      status_code: status,
      body: body
    } = update_user_path(user, change_params, current_user_token)

    token_or_nil =
      case headers |> token_or_nil() do
        [] ->
          ""

        [token] ->
          token
      end

    {:ok, current_user_or_nl} =
      headers
      |> token_or_nil()
      |> current_user_or_nil()

    %{
      current_user: current_user_or_nl,
      token: token_or_nil,
      info: {status, body |> Jason.decode!()}
    }
  end

  def show_user(current_user_token, requested_user) do
    %HTTPoison.Response{body: body, status_code: status} =
      show_user_path({"authorization", "Bearer " <> current_user_token}, requested_user.uuid)

    body = body |> Jason.decode!()
    viewed_user = if body["user"], do: body["user"], else: body

    %{viewed_user: viewed_user, status: status}
  end

  # Support
  def token_or_nil(headers) do
    for {"authorization", "Bearer " <> token} <- headers, do: token
  end

  def current_user_or_nil(token_or_nil) do
    case token_or_nil do
      [] ->
        {:ok, nil}

      [token] ->
        {:ok, current_user, _claims} = Guardian.resource_from_token(token)

        {:ok, current_user}
    end
  end
end
