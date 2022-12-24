require 'socket'

server = TCPServer.new(1337)

interviews = [
  { name: 'Gemma', date: '01/02/2022' },
  { name: 'Timmo', date: '02/02/2022' },
  { name: 'Peter', date: '03/02/2022' }
]

loop do
  client = server.accept

  request_line = client.readline
  method_token, target, version_number = request_line.split

  case [method_token, target]
  when %w[GET /show/interviews]
    response_status_code = '200 OK'
    content_type = 'text/html'
    response_message = ''

    response_message << "<ul>\n"
    interviews.each do |interview|
      response_message << "<li> #{interview[:name]}</b> was born on #{interview[:date]}!</li>\n"
    end
    response_message << "</ul>\n"
    response_message << <<~STR
      <form action='/add/interview' method='post' enctype='application/x-www-form-urlencoded'>
        <p><label>Name <input type='text' name='name'></label></p>
        <p><label>Interview <input type='date' name='date'></label></p>
        <p><button>Submit interview</button></p>
      </form>
    STR
  when %w[post /add/interview]
    response_status_code = '303 See Other'
    content_type = 'text/html'
    response_message = ''

    all_headers = {}
    loop do
      line = client.readline
      break if line == "\r\n"

      header_name, value = line.split(': ')
      all_headers[header_name] = value
    end
    body = client.read(all_headers['Content-Length'].to_i)

    require 'uri'
    new_interview = URI.decode_www_form(body).to_h

    interviews << new_interview.transform_keys(&:to_sym)

  else
    response_status_code = '200 OK'
    response_message = "✅ Received a #{method_token} request to #{target} with #{version_number}"
    content_type = 'text/plain'
  end

  puts response_message

  http_response = <<~MSG
    #{version_number} #{response_status_code}
    Content-Type: #{content_type}; charset=#{response_message.encoding.name}
    Location: /show/interviews

    #{response_message}
  MSG

  client.puts http_response
  client.close
end
