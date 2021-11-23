defmodule Blackjack.Starter do
  require Logger

  alias Blackjack.Supervisor

  @alphabet Enum.concat([?0..?9, ?A..?Z, ?a..?z])

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker
    }
  end

  def start_link([pid]) do
    Swarm.register_name(
      "blackjack_#{randstring(10)}" |> String.to_atom(),
      Supervisor,
      :start_link,
      [pid]
    )

    # Swarm.register_name("blackjack_#{randstring(10)}" |> String.to_atom(), pid)
    # :ignore
  end

  def randstring(count) do
    # Technically not needed, but just to illustrate we're
    # relying on the PRNG for this in random/1
    :rand.seed(:exsplus, :os.timestamp())

    Stream.repeatedly(&random_char_from_alphabet/0)
    |> Enum.take(count)
    |> List.to_string()
  end

  defp random_char_from_alphabet() do
    Enum.random(@alphabet)
  end
end
