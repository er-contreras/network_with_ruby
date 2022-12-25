require 'socket'
require 'yaml/store'

server = TCPServer.new(1337)

store = YAML::Store.new('data.yml')

loop do
  # the accept method blocks until the connection is established,
  # and then returns a new TCPSocket object representing the connection.
  client = server.accept

  # The readline method is a method of the TCPSocket class that reads a line of data from the socket connection
  request_line = client.readline # reads a line of data from the client => Example: "GET /index.html HTTP/1.1"
  method_token, target, version_number = request_line.split

  case [method_token, target]
  when ['GET', '/show/interviews']
    response_status_code = '200 OK'
    content_type = 'text/html'
    response_message = "<ul>\n"

    all_interviews = {}
    store.transaction do
      all_interviews = store[:interviews]
    end

    all_interviews.each do |interview|
      response_message << "<li> #{interview[:name]}</b> will come in #{interview[:data]}!</li>\n"
    end
    response_message << "</ul>\n"
    response_message << <<~STR
      <form action="/add/interview" method="post" enctype="application/x-www-form-urlencoded">
        <p><label>Name <input type="text" name"name"></label></p>
        <p><label>Interview <input type="date" name"date"></label></p>
        <p><button>Reserve Interview</button></p>
      </form>
    STR

  when ['POST', '/add/interview']
    response_status_code = '303 See Other'
    content_type = 'text/html'
    response_message = ''

    all_headers = {}
    while true
      line = client.readline # reads a line of data from the client => "Content-Type: text/html"
      # When the user enters a line ending, the loop will be exited and the program will continue execution after the loop
      break if line == "\r\n" # The \r character represents a carriage return

      header_name, value = line.split(': ')
      all_headers[header_name] = value
    end
    body = client.read(all_headers['Content-Length'].to_i) # => "name=John+Doe&email=john%40example.com&phone=555-555-5555"

    require 'uri'
    new_interview = URI.decode_www_form(body).to_h # => {"name"=>"John Doe", "email"=>"john@example.com", "phone"=>"555-555-5555"}

    store.transaction do
      store[:interviews] << new_interview.transform_keys(&:to_sym) # => {:name=>"John Doe", :email=>"john@
    end
  else
    response_status_code = '200 OK'
    response_message = "✅ Received a #{method_token} request to #{target} with #{version_number}"
    content_type = 'text/plain'
  end

  http_response = <<~MSG
    #{version_number} #{response_status_code}
    Content-Type: #{content_type}; charset=#{response_message.encoding.name}
    Location: /show/interviews

    #{response_message}
  MSG

  client.puts http_response
  client.close
end
