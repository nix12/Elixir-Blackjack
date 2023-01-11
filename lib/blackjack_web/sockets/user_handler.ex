defmodule BlackjackWeb.Sockets.UserHandler do
  require Logger

  @behaviour :cowboy_websocket

  alias Blackjack.Repo
  alias Blackjack.Policy
  alias Blackjack.Accounts.Authentication.Guardian
  alias Blackjack.Accounts.{User, UserManager, AccountsRegistry, Friendship, Inbox}

  def init(request, _state) do
    "Bearer " <> token = request.headers["authorization"]
    {:ok, %{"user" => user}} = Guardian.decode_and_verify(token)
    state = %{current_user: user}

    {:cowboy_websocket, request, state, %{idle_timeout: :timer.hours(2)}}
  end

  def websocket_init(%{current_user: %{"id" => id}} = state) do
    [{user_pid, _}] = Horde.Registry.lookup(AccountsRegistry, id)

    Process.monitor(user_pid)
    send(self(), {:connect})
    {[], state, :hibernate}
  end

  def websocket_handle({:text, json}, state) do
    %{"action" => [type, _action], "payload" => _} = data = json |> Jason.decode!()

    case type do
      "friendship" ->
        send(self(), {:friendship, data})

      "messages" ->
        send(self(), {:message, data})
    end

    {[], state, :hibernate}
  end

  def websocket_info({:connect}, %{current_user: current_user} = state) do
    message = %{message: "CONNECTED with user #{current_user["username"]}"} |> Jason.encode!()
    {[text: message], state}
  end

  def websocket_info(
        {:friendship, %{"action" => ["friendship", "create"], "payload" => data}},
        %{current_user: current_user} = state
      ) do
    with requested_user <- Repo.get_by(User, username: data["requested_user_username"]),
         :ok <- Bodyguard.permit(Policy, :create_friendship, current_user, %Friendship{}),
         {:ok, _friendship} <- UserManager.create_friendship(current_user, requested_user) do
      payload = %{payload: "Friend request sent to #{requested_user.username}"} |> Jason.encode!()

      {[text: payload], state}
    else
      {:error, error} ->
        payload =
          %{
            payload: "Failed to establish friendship, please try again later. Reason: #{error}"
          }
          |> Jason.encode!()

        {[text: payload], state}
    end
  end

  def websocket_info(
        {:friendship, %{"action" => ["friendship", "accept"], "payload" => data}},
        %{current_user: current_user} = state
      ) do
    with friendship <-
           Repo.get_by(Friendship,
             user_id: current_user["id"],
             friend_id: data["requested_user_username"]
           ),
         :ok <- Bodyguard.permit(Policy, :accept_friendship, current_user, friendship),
         {:ok, _friendship} <-
           UserManager.accept_friendship(current_user, data["requested_user_username"]) do
      username = data["requested_user_username"] |> UserManager.get_user() |> Map.get(:username)

      payload = %{payload: %{success: %{accept_friend: username}}} |> Jason.encode!()

      {[text: payload], state}
    else
      {:error, error} ->
        payload =
          %{
            payload: "Failed to establish friendship, please try again later. Reason: #{error}"
          }
          |> Jason.encode!()

        {[text: payload], state}
    end
  end

  def websocket_info(
        {:friendship, %{"action" => ["friendship", "decline"], "payload" => data}},
        %{current_user: current_user} = state
      ) do
    with friendship <-
           Repo.get_by(Friendship,
             user_id: current_user["id"],
             friend_id: data["requested_user_username"]
           ),
         :ok <- Bodyguard.permit(Policy, :decline_friendship, current_user, friendship),
         {:ok, _friendship} <-
           UserManager.decline_friendship(current_user, data["requested_user_username"]) do
      username = data["requested_user_username"] |> UserManager.get_user() |> Map.get(:username)

      payload = %{payload: %{success: %{decline_friend: username}}} |> Jason.encode!()

      {[text: payload], state}
    else
      {:error, error} ->
        payload =
          %{
            payload: "Failed to establish friendship, please try again later. Reason: #{error}"
          }
          |> Jason.encode!()

        {[text: payload], state}
    end
  end

  def websocket_info(
        {:friendship, %{"action" => ["friendship", "remove"], "payload" => data}},
        %{current_user: current_user} = state
      ) do
    with friendship <-
           Repo.get_by(Friendship,
             user_id: current_user["id"],
             friend_id: data["requested_user_username"]
           ),
         :ok <- Bodyguard.permit(Policy, :remove_friendship, current_user, friendship),
         {:ok, _friendship} <-
           UserManager.remove_friendship(current_user, data["requested_user_username"]) do
      username = data["requested_user_username"] |> UserManager.get_user() |> Map.get(:username)

      payload = %{payload: %{success: %{remove_friend: username}}} |> Jason.encode!()

      {[text: payload], state}
    else
      {:error, error} ->
        payload =
          %{
            payload: "Failed to establish friendship, please try again later. Reason: #{error}"
          }
          |> Jason.encode!()

        {[text: payload], state}
    end
  end

  def websocket_info(
        {:friendship, %{"action" => ["friendship", "read"]}},
        %{current_user: current_user} = state
      ) do
    with :ok <- Bodyguard.permit(Policy, :read_friendships, current_user, current_user["id"]) do
      payload = %{payload: UserManager.get_friends(current_user["id"])} |> Jason.encode!()

      {[text: payload], state}
    end
  end

  def websocket_info(
        {:message, %{"action" => ["message", "create"], "payload" => data}},
        %{current_user: current_user} = state
      ) do
    with requested_user <- Repo.get_by(User, username: data["requested_user_username"]),
         :ok <- Bodyguard.permit(Policy, :create_message, current_user, %User{}),
         {:ok, _friendship} <- UserManager.create_friendship(current_user, requested_user) do
      payload = %{payload: "Friend request sent to #{requested_user.username}"} |> Jason.encode!()

      {[text: payload], state}
    else
      {:error, error} ->
        payload =
          %{
            payload: "Failed to establish friendship, please try again later. Reason: #{error}"
          }
          |> Jason.encode!()

        {[text: payload], state}
    end
  end

  def websocket_info({:message, %{"action" => ["message", "delete"], "payload" => data}}, state) do
  end

  def websocket_info(
        {:message, %{"action" => ["message", %{"read" => "all"}], "payload" => data}},
        state
      ) do
  end

  def websocket_info(
        {:message, %{"action" => ["message", %{"read" => "notifications"}], "payload" => data}},
        state
      ) do
  end

  def websocket_info(
        {:message, %{"action" => ["message", %{"read" => "conversations"}], "payload" => data}},
        state
      ) do
  end

  def websocket_info({:DOWN, _ref, :process, _object, _reason}, state) do
    Process.exit(self(), :normal)
    {:ok, state}
  end
end
