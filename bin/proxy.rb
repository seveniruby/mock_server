require 'rubygems'
require 'em-proxy'
require 'yaml'
require 'json'
require 'base64'

module EventMachine
	class Connection
		def close_connection after_writing = false
			EM.next_tick do
				EventMachine::close_connection @signature, after_writing
			end
		end
	end
end

def help
	puts "
	proxyserver config  #generate the proxy.conf
	proxyserver start   #start the proxy server
	"
end

case ARGV[0]
when 'config'
	config={"server"=>{"ip"=>'0.0.0.0','port'=>'8077', 'log'=>'proxy.log', 'log_encoding'=>'', 'encoding'=>''},'forward'=>{'baidu1'=>{"host"=>'www.baidu.com',"port"=>'80','encoding'=>''},'baidu2'=>{"host"=>'www.baidu.com',"port"=>'80','encoding'=>''}}}
	File.open("proxy.conf",'w') do |f|
		f.puts config.to_yaml
	end
	puts "proxy.conf OK"
when 'help'
	help
when nil
	help

when 'start'
	debug=false
	debug=true if ARGV[1]=='debug'
	config=YAML::load IO.read('proxy.conf')
	log=File.open(config['server']['log'],'a+')
	Proxy.start(:host => config['server']['ip'], :port => config['server']['port'], :debug => debug ) do |conn|
		config['forward'].each do |k,v|
			conn.server k, :host =>v['host'], :port =>v['port']
		end
		# modify / process request stream
		conn.on_data do |data|
			if log
				if config['server']['log_encoding']
					req_log=data.encode(config['server']['log_encoding'],config['server']['encoding'])
				else
					req_log=data
				end
				
				log.puts "request start"
				log.puts "request #{req_log.unpack('H*')[0].to_s}"
				log.flush
			end
			data
		end
		# modify / process response stream
		conn.on_response do |backend, resp|
			if log
				if config['server']['log_encoding']
					res_log=resp.encode(config['server']['log_encoding'],config['forward'][backend.to_s]['encoding'])
				else
					res_log=resp
				end
				log.puts "#{backend} #{res_log.unpack('H*')[0].to_s}"
				log.flush
			end
			#需要增加多转发时候的请求销毁
			resp
		end

		# termination logic
		conn.on_finish do |backend, name|
			if log
				log.puts backend+' end'
				log.flush
			end
			# terminate connection (in duplex mode, you can terminate when prod is done)
			# unbind if backend == :srv
		end
	end

end


