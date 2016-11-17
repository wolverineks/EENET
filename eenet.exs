defmodule EENET do

  # EENET
  def start(username) do
    server = spawn(EENET, :init, [username])
    Process.register(client, EENET)

    server
  end

  def connect(node) do
    Node.connect(node)
  end

  def send(server, msg) do
    Kernel.send(server, {:send, msg})
  end

  # Server
  def init(username) do
    loop(username)
  end

  def loop(username) do
    receive do
      {:send, msg} ->
        IO.puts(~s{#{username}: #{msg}})
        nodes = Enum.map(Node.list, &({EENET, &1}))
        Enum.each(nodes, fn(node) -> Kernel.send(node, {:new_msg, username, msg}) end)

        loop(username)

      {:new_msg, from, msg} ->
        IO.puts(~s{#{from}: #{msg}})
        loop(username)

    end
  end

end
