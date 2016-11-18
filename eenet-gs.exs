defmodule EENETGS do
  use GenServer

  @bootstrap :"a@wolv-MacBookAir"

  # CLIENT
  def setup(username) do
    start(username)
    connect(@bootstrap)
    Process.sleep 300
    members = request_usernames
    Process.sleep 300
    set_members(members)
    Process.sleep 300
    announce(username)

    IO.puts "Setup complete"
  end

  # Used to send a message to all connected nodes
  def broadcast(msg) do
    nodes = Node.list()
    username = GenServer.call(__MODULE__, {:username})

    display_message(username, msg)
    Enum.each(nodes, fn(node) ->
      send_message(node, username, msg)
    end)
  end

  # Used to send direct messages
  def send_message(username, msg) do
    members = GenServer.call(__MODULE__, {:get_members})
    member = Enum.find(members, fn(member) -> member.username == username end)
    node = member.node

    GenServer.cast({__MODULE__, node}, {:new_msg, username, msg})
  end
  # Used by broadcast to send individual messages
  def send_message(node, username, msg) do
    GenServer.cast({__MODULE__, node}, {:new_msg, username, msg})
  end

  def start(username) do
    GenServer.start_link(__MODULE__, %{username: username, members: []}, [name: __MODULE__])
  end

  def connect(node) do
    Node.connect(node)
  end

  def display_message(from, msg) do
    IO.puts "[#{from}] - #{msg}"
  end

  def request_usernames do
    nodes = Node.list
    members = Enum.map(nodes, fn(node) ->
      %{node: node, username: request_username(node)}
    end)
  end

  def request_username(node) do
    GenServer.call({__MODULE__, node}, {:username})
  end

  def get_username(node) do
    members = get_members
    member = Enum.find(members, fn(member) -> member.node == node end)

    member.username
  end

  def get_members do
    GenServer.call(__MODULE__, {:get_members})
  end

  def set_members(members) do
    GenServer.cast(__MODULE__, {:set_members, members})
  end

  def announce(username) do
    nodes = Node.list()

    Enum.each(nodes, fn(node) ->
      member = %{node: node(), username: username}

      GenServer.cast({__MODULE__, node}, {:join, member})
    end)
  end

  # SERVER
  def init(state) do
    {:ok, state}
  end

  # Introduce to other node
  def handle_call({:username}, from, state) do
    {:reply, state.username, state}
  end

  # Return members list
  def handle_call({:get_members}, from, state) do
    {:reply, state.members, state}
  end

  # Used to catch all other requests
  def handle_call(_, from, state) do
    error_msg =
    "Sorry, I don't know what you want."

    {:reply, error_msg, state}
  end

  # Update state with new members
  def handle_cast({:set_members, members}, state) do
    {:noreply, %{state | members: members}}
  end

  # Catch incoming messages
  def handle_cast({:new_msg, from, msg}, state) do
    display_message(from, msg)

    {:noreply, state}
  end

  # New member joined network
  def handle_cast({:join, member}, state) do
    username = member.username
    display_message("INFO", "#{username} joined the network")
    new_members = [member | state.members]
    new_state = %{state | members: new_members}

    {:noreply, new_state }
  end

end
