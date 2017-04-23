class GcmFcm

	def self.sendNotification(isFcm,ids)
		apiKey = "XXXXXXXXXXX"    # API Key

    	data = {   
    				"registration_ids" => ids, # maximum 100 id's to send notofocation at a time [id, id1, id2, .....]
               		"data" => {
	                 	"notification" =>  {
	                   		"body" =>  "New Message",
	                   		"title" =>  "Test"
	                 	},
                 		"data"=> {
                   			# you can send 4kb json data 
                 		}
               		},
              	}

        if isFcm
			url = "https://fcm.googleapis.com/fcm/send"
        else
			url = "https://android.googleapis.com/gcm/send"
        end

    	return androidPushNotification(apiKey,url,data)
	end


	def androidPushNotification(apiKey,url,data)
	    uri=URI.parse(url)
	    require 'net/http'
	    req = Net::HTTP.new(uri.host, uri.port)
	    req1 = Net::HTTP::Post.new(uri.path)
	    req.verify_mode = OpenSSL::SSL::VERIFY_NONE
	    req.use_ssl = true
	    req1.body=JSON.generate(data)
	    req1["Content-Type"] = "application/json"
	    req1["Authorization"] = "key="+apiKey

	    res= req.request(req1)
	    Rails.logger.info(res.body)
	    return  res.body
	end
end