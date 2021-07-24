# http_proxy=http://192.168.49.1:8000 https_proxy=http://192.168.49.1:8000 asdf install elixir latest

defmodule App do
  def start(client_name) do
    spawn(fn -> loop(client_name) end)
  end

  def loop(name) do
    receive do
      message ->
        IO.puts("#{name} received `#{message}`")
        loop(name)
    end
  end
end

{topic1, topic2} = {:erlang, :elixir}
# {:erlang, :elixir}

{:ok, pid} = PubSub.start_link()
# {:ok, "#PID<0.99.0>"}

{pid1, pid2, pid3} = {
  App.start("John"),
  App.start("Nick"),
  App.start("Time")
}
# {"#PID<0.106.0>", "#PID<0.107.0>", "#PID<0.108.0>"}

PubSub.subscribe(pid1, topic1)
# :ok
PubSub.subscribe(pid2, topic1)
# :ok
PubSub.subscribe(pid3, topic2)
# :ok

PubSub.publish(topic1, "#{topic1} is great!")
# something
# something
# :ok

PubSub.publish(topic2, "#{topic2} is so cool, dude")
# something
# :ok

# subscribe(pid, topic)
# publish(topic, message)

# Node.connect(String.to_atom("blackjack@Developer"))

# Blackjack.Accounts.Server.create_user("mastersd")
# Blackjack.Core.create_player("mastersd")
# Blackjack.initialize_table
# Blackjack.build

# Blackjack.Accounts.Server.create_user("test")
# Blackjack.Core.create_player("test")

# Blackjack.Core.Players.join_table("high rollers", "mastersd")

# Blackjack.Core.Players.join_table("high rollers", "test")

# Blackjack.Core.Tables.turn("high rollers")




# System.cmd("websocat", [
#   "ws://localhost:4000",
#   "-H", "Connection: Upgrade",
#   "-H", "Upgrade: websocket",
#   "-H", "Host: localhost:4000",
#   "-H", "Origin: http://example.com"
# ])


:httpc.request(
  :get,
  {
    'http://0.0.0.0:4000',
      [
        {'Connection', 'Upgrade'},
        {'Upgrade', 'websocket'},
        {'Host', '0.0.0.0:4000'},
        {'Origin', 'http://example.com'},
        {'sec-websocket-key', 'SGVsbG8s*HvmxkIQ=='},
        {'sec-websocket-version', '13'}
    ],
  },
  [],
  []
)
