defmodule EENET do

  # EENET
  def start(username), do: spawn(__MODULE__, :init, [username])

  def connect(node) do
    Node.connect(node)
  end

  def send(server, msg) do
    Kernel.send(server, {:send, msg})
  end

  # Server
  def init(username) do
    Process.register(self, EENET)
    initial_state = %{username: username}

    loop(initial_state)
  end

  def display_message(from, msg) do
    IO.puts(~s{#{from}: #{msg}})
  end

  def broadcast(from, msg) do
    nodes = Enum.map(Node.list, &({EENET, &1}))
    Enum.each(nodes, fn(node) -> Kernel.send(node, {:new_msg, from, msg}) end)
  end

  def loop(state) do
    receive do
      {:send, msg} ->
        username = state.username
        broadcast(username, msg)
        display_message(username, msg)
        loop(state)

      {:new_msg, from, msg} ->
        display_message(from, msg)
        loop(state)

    end
  end

end
