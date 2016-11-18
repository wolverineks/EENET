defmodule EENET do

  # EENET
  def start(username), do: spawn(__MODULE__, :init, [username])

  def connect(node) do
    Node.connect(node)

    nodes = Node.list


  end

  def send(server, msg) do
    Kernel.send(server, {:send, msg})
  end

  def request_usernames do
    node = Node.list
    Enum.map(nodes, fn(node) -> request_username(node) end
  end

  def request_username(node) do
    node = {__MODULE__, node}
    Kernel.send(node, {:request_username, node()})
  end

  # Server
  def init(username) do
    Process.register(self, __MODULE__)
    initial_state = %{username: username}

    loop(initial_state)
  end

  def display_message(from, msg) do
    IO.puts(~s{#{from}: #{msg}})
  end

  def broadcast(type, from, msg) do
    nodes = Enum.map(Node.list, &({__MODULE__, &1}))
    Enum.each(nodes, fn(node) -> Kernel.send(node, {type, from, msg}) end)
  end

  def loop(state) do
    username = state.username

    receive do
      {:connect, username} ->
        broadcast(:connect, username, username)

      {:send, msg} ->
        broadcast(username, msg)
        display_message(username, msg)
        loop(state)

      {:new_msg, from, msg} ->
        display_message(from, msg)
        loop(state)

      {:request_username, node} ->
        from = {__MODULE__, node}
        Kernel.send(from, {:username, username})
        loop(state)

      {:username, username} ->
        IO.puts username
        loop(state)
    end
  end

end
