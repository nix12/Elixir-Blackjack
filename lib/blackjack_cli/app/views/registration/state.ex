defmodule BlackjackCLI.Views.Registration.State do
  @doc """
    Updates registration form state based on key and input actions
    and maintains form state by using an Agent
  """
  require Logger

  import Ratatouille.Constants, only: [key: 1]

  @registry Registry.Web

  @space_bar key(:space)
  @tab key(:tab)
  @enter key(:enter)

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]
  @spec update(map(), tuple()) :: map()
  def update(model, msg) do
    case msg do
      {:event, %{key: @tab}} ->
        Agent.update(
          Blackjack.via_tuple(@registry, :registration),
          &%{&1 | tab_count: &1.tab_count + 1}
        )

        update_user(%{model | input: ""})

      {:event, %{key: key}} when key in @delete_keys ->
        update_user(%{model | input: String.slice(model.input, 0..-2)})

      {:event, %{key: @space_bar}} ->
        update_user(%{
          model
          | input: (model.input |> to_string |> String.replace(~r/^[[:digit:]]+$/, "")) <> " "
        })

      {:event, %{ch: ch}} when ch > 0 ->
        update_user(%{
          model
          | input:
              (model.input |> to_string |> String.replace(~r/^[[:digit:]]+$/, "")) <>
                <<ch::utf8>>
        })

      {:event, %{key: @enter}} ->
        password = Agent.get(Blackjack.via_tuple(@registry, :registration), & &1.password)

        password_confirmation =
          Agent.get(Blackjack.via_tuple(@registry, :registration), & &1.password_confirmation)

        user_data = %{
          user: %{
            username: Agent.get(Blackjack.via_tuple(@registry, :registration), & &1.username),
            password_hash: password
          }
        }

        with :ok <- validate_username(user_data.user.username),
             :ok <- validate_password(password, password_confirmation) do
          {code, resource} = register_request(user_data)

          register_verify(model, code, resource)
        else
          {:error, message} ->
            update_errors(message)
            %{model | input: model.input, screen: :registration}
        end

      _ ->
        update_user(model)
    end
  end

  @doc """
    Starts a process for maintianing registration form state
  """
  @spec start_registration :: {:ok, pid()}
  def start_registration do
    Agent.start_link(
      fn ->
        %{
          tab_count: 0,
          username: "",
          password: "",
          password_confirmation: "",
          errors: ""
        }
      end,
      name: Blackjack.via_tuple(@registry, :registration)
    )
  end

  defp update_errors(message) do
    Agent.update(Blackjack.via_tuple(@registry, :registration), &%{&1 | errors: message})
  end

  @spec update_user(map()) :: map()
  defp update_user(%{input: input, screen: screen} = model) do
    tab_count =
      Agent.get(
        Blackjack.via_tuple(@registry, :registration),
        & &1.tab_count
      )

    case tab_count do
      0 ->
        Agent.update(
          Blackjack.via_tuple(@registry, :registration),
          &%{
            &1
            | username: input
          }
        )

        %{model | input: input, screen: screen}

      1 ->
        Agent.update(
          Blackjack.via_tuple(@registry, :registration),
          &%{
            &1
            | password: input
          }
        )

        %{model | input: input, screen: screen}

      2 ->
        Agent.update(
          Blackjack.via_tuple(@registry, :registration),
          &%{
            &1
            | password_confirmation: input
          }
        )

        %{model | input: input, screen: screen}

      _ ->
        Agent.update(
          Blackjack.via_tuple(@registry, :registration),
          fn registration ->
            %{registration | tab_count: 0}
          end
        )

        model
    end
  end

  defp register_request(user_data) do
    {:ok, {{_protocol, code, _message}, _meta, resource}} =
      :httpc.request(
        :post,
        {'http://localhost:#{Application.get_env(:blackjack, :port)}/register', [],
         'application/json', Jason.encode!(user_data)},
        [],
        []
      )

    {code, Jason.decode!(resource)}
  end

  defp login_request(user) do
    {:ok, {{_protocol, code, _message}, _meta, resource}} =
      :httpc.request(
        :post,
        {'http://localhost:#{Application.get_env(:blackjack, :port)}/login', [],
         'application/json', Jason.encode!(user)},
        [],
        []
      )

    Logger.info(inspect(resource))
    {code, Jason.decode!(resource)}
  end

  defp register_verify(model, code, user) do
    user_data = %{
      user: %{
        username: Agent.get(Blackjack.via_tuple(@registry, :registration), & &1.username),
        password_hash: Agent.get(Blackjack.via_tuple(@registry, :registration), & &1.password)
      }
    }

    case code do
      code when code >= 200 and code < 300 ->
        case login_request(user_data) do
          {login_code, resource} when login_code >= 200 and login_code < 300 ->
            Agent.stop(Blackjack.via_tuple(@registry, :registration), :normal)
            %{model | input: 0, screen: :login, token: resource["token"]}

          {_, _error} ->
            Agent.update(
              Blackjack.via_tuple(@registry, :login),
              &%{&1 | errors: "created account but failed to login due to server error."}
            )

            %{model | input: 0, screen: :login}
        end

      _ ->
        update_errors(user["error"])
        %{model | input: "", screen: :registration}
    end
  end

  defp validate_username(username) do
    case Blackjack.blank?(username) do
      true ->
        {:error, "username cannot be blank."}

      _ ->
        :ok
    end
  end

  defp validate_password(password, password_confirmation) do
    case Blackjack.blank?(password) or Blackjack.blank?(password_confirmation) do
      true ->
        {:error, "password and/or password confirmation cannot be blank."}

      _ ->
        if password == password_confirmation do
          :ok
        else
          {:error, "password and password_confirmation must match."}
        end
    end
  end
end
