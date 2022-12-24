require 'socket'

# The socket library allows us to create a TCP server socket
# TCP creates a socket on a specific port that can be identified as the application that’s using it
server = TCPServer.new(1337)

# Accept Incoming Connections
# we decide what we want to give the client when a connection is made.
# In a loop, we accept any clients through #accept.
# Once a client is accepted as a connection, we receive information in a form of an IO object
loop do
  client = server.accept

  # Get the input from client side
  client.puts "What's your name?"
  input = client.gets
  puts "Received #{input.chomp} from client socket on 1337"
  client.puts "Hi, #{input.chomp}! You've successfully connected to the server socket."

  # Close client connection
  puts "Closing client socket"
  client.puts "Goodbye #{input}"
  client.close
end