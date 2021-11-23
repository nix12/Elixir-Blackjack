defmodule BlackjackCLI.Views.Login.State do
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

  def update(model, msg) do
    case msg do
      {:event, %{key: @tab}} ->
        Agent.update(Blackjack.via_tuple(@registry, :login), &%{&1 | active: !&1.active})

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
        user_data = %{
          user: %{
            username: Agent.get(Blackjack.via_tuple(@registry, :login), & &1.username),
            password_hash: Agent.get(Blackjack.via_tuple(@registry, :login), & &1.password)
          }
        }

        with :ok <- validate_username(user_data.user.username),
             :ok <- validate_password(user_data.user.password_hash) do
          {code, resource} = login_request(user_data)

          login_verify(model, code, resource)
        else
          {:error, message} ->
            Agent.update(Blackjack.via_tuple(@registry, :login), &%{&1 | errors: message})
            update_user(%{model | input: model.input, screen: :login})
        end

      _ ->
        update_user(model)
    end
  end

  def start_login do
    Agent.start_link(
      fn ->
        %{active: true, username: "", password: "", errors: ""}
      end,
      name: Blackjack.via_tuple(@registry, :login)
    )
  end

  defp update_user(%{input: input, screen: screen} = model) do
    if Agent.get(Blackjack.via_tuple(@registry, :login), & &1.active) do
      Agent.update(
        Blackjack.via_tuple(@registry, :login),
        &%{&1 | username: input}
      )

      %{model | input: input, screen: screen}
    else
      Agent.update(
        Blackjack.via_tuple(@registry, :login),
        &%{&1 | password: input}
      )

      %{model | input: input, screen: screen}
    end
  end

  defp login_request(user_data) do
    {:ok, {{_protocol, code, _message}, _meta, resource}} =
      :httpc.request(
        :post,
        {'http://localhost:#{Application.get_env(:blackjack, :port)}/login', [],
         'application/json', Jason.encode!(user_data)},
        [],
        []
      )

    Logger.info("RESOURCE: #{inspect(resource)}")
    {code, Jason.decode!(resource)}
  end

  defp login_verify(model, code, resource) do
    case code do
      code when code >= 200 and code < 300 ->
        Agent.stop(Blackjack.via_tuple(@registry, :login), :normal)

        %{
          model
          | screen: :menu,
            token: resource["token"],
            input: 0,
            user: %{username: resource["user"]["username"]},
            menu: true
        }

      _ ->
        Agent.update(Blackjack.via_tuple(@registry, :login), &%{&1 | errors: resource["errors"]})

        %{model | screen: :login, token: nil}
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

  defp validate_password(password) do
    case Blackjack.blank?(password) do
      true ->
        {:error, "password cannot be blank."}

      _ ->
        :ok
    end
  end
end
