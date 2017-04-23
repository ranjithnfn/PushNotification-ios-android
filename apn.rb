class Apn

	def self.sendNotification(isApnHttp2,device_token)
		
		# should be less than or equal to 4096 bytes
		payload = '{"aps":{"alert":{"title" : "3 more days", "body" : "Please verify your email",  "action-loc-key" : "PLAY" },"sound":"default"}}'

		if (isApnHttp2)
			return apnHttp2(device_token,payload)  # Apple change apn notification https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingwithAPNs.html
		else
			return apnOld(device_token,payload)
		end
	end

# 	Apple push notification apn/http2
	def apnHttp2(device_token,payload)

	 	require 'socket'
		require 'http/2'

		if Rails.env.production?
			uri = URI.parse("https://api.push.apple.com/3/device/#{device_token}")
			cert = File.read('public/xxxx.pem')  # apple push certificate convert p12 to pem 
		else
			uri = URI.parse("https://api.development.push.apple.com/3/device/#{device_token}")
			cert = File.read('public/xxxx.pem')  # apple push certificate convert p12 to pem 
		end
			

		tcp = TCPSocket.new(uri.host, uri.port)

		ctx = OpenSSL::SSL::SSLContext.new
		ctx.key = OpenSSL::PKey::RSA.new(cert) #set passphrase here, if any
		ctx.cert = OpenSSL::X509::Certificate.new(cert)
		   
		# For ALPN support, Ruby >= 2.3 and OpenSSL >= 1.0.2 are required
		sock = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
		sock.connect

		conn = HTTP2::Client.new
		stream = conn.new_stream
		# log = Logger.new(stream.id)

		conn.on(:frame) do |bytes|
		  puts "Sending bytes: #{bytes.unpack("H*").first}"
		  sock.print bytes
		  sock.flush
		end
		# conn.on(:frame_sent) do |frame|
		#   puts "Sent frame: #{frame.inspect}"
		# end
		# conn.on(:frame_received) do |frame|
		#   puts "Received frame: #{frame.inspect}"
		# end

		# conn.on(:promise) do |promise|
		#   promise.on(:headers) do |h|
		#     log.info "promise headers: #{h}"
		#   end

		#   promise.on(:data) do |d|
		#     log.info "promise data chunk: <<#{d.size}>>"
		#   end
		# end

		# conn.on(:altsvc) do |f|
		#   log.info "received ALTSVC #{f}"
		# end

		# stream.on(:close) do
		#   log.info 'stream closed'
		# end

		# stream.on(:half_close) do
		#   log.info 'closing client-end of the stream'
		# end

		# stream.on(:headers) do |h|
		#   log.info "response headers: #{h}"
		# end

		# stream.on(:data) do |d|
		#   log.info "response data chunk: <<#{d}>>"
		# end

		# stream.on(:altsvc) do |f|
		#   log.info "received ALTSVC #{f}"
		# end

		head = {
		  ':scheme' => uri.scheme,
		  ':method' => "POST",
		  ':path' => uri.path,
		  'content-length' => payload.bytesize.to_s, # should be less than or equal to 4096 bytes
		  'apns-topic' => "nfn.ViBo" # Your Apllication bundle ID
		}

		puts 'Sending HTTP 2.0 request'
		
		stream.headers(head, end_stream: false)
		stream.data(payload)

		while !sock.closed? && !sock.eof?
		  data = sock.read_nonblock(1024)
		  puts "Received bytes: #{data.unpack("H*").first}"

		  begin
		    conn << data
		   	sock.close
		   	tcp.close

		  rescue => e
		    puts "#{e.class} exception: #{e.message} - closing socket."
		    e.backtrace.each { |l| puts "\t" + l }
		    sock.close
		   	tcp.close
		  end
		end
	    return hash     
  	end


 	def apnOld(device_token,payload)

	      if Rails.env.production?
	        cert = File.read('public/xxxx.pem')
	        sock = TCPSocket.new('gateway.push.apple.com', 2195) #development gateway
	      else
	        cert = File.read('public/xxxx.pem')
	        sock = TCPSocket.new('gateway.sandbox.push.apple.com', 2195) #development gateway
	      end

	      ctx = OpenSSL::SSL::SSLContext.new
	      ctx.key = OpenSSL::PKey::RSA.new(cert) #set passphrase here, if any
	      ctx.cert = OpenSSL::X509::Certificate.new(cert)

	      ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
	      ssl.connect

	      # Sample Payload  -->  payload = {"aps" => {"alert" => respon, "sound" => 'default'}, "user_defined_key" => { same payload ... } }

	      json = payload.to_json()
	      token =  [(id1)].pack('H*') #something like 2c0cad 01d1465 346786a9 3a07613f2 b03f0b94b6 8dde3993 d9017224 ad068d36
	      apnsMessage = "00 #{token}0#{json.length.chr}#{json}"
	      result = ssl.write(apnsMessage)
	            
	      ssl.close
	      sock.close	    
	end


end