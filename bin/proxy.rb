#encoding: utf-8
require 'rubygems'
require 'em-proxy'
require 'yaml'
require 'json'
require 'base64'

#解决jruby下的一个bug
module EventMachine
	class Connection
		def close_connection after_writing = false
			EM.next_tick do
				EventMachine::close_connection @signature, after_writing
			end
		end
	end
end

class ProxyServer
	def help
		puts "
	proxyserver config  #generate the proxy.conf
	proxyserver start   #start the proxy server
		"
	end

	def log(backend,data)
		if backend.to_s=='req'
			if @config['server']['log_encoding'] != @config['server']['encoding']
				data=data.encode(@config['server']['log_encoding'],@config['server']['encoding'])
			end
		else

			if @config['server']['log_encoding'] != @config['forward'][backend.to_s]['encoding']
				data=data.encode(@config['server']['log_encoding'],@config['forward'][backend.to_s]['encoding'])
			end
		end
		#支持多种格式
		log_file=nil
		#支持运行时move文件
		if !File.exist? @config['server']['log']+"."+@config['server']['log_format'].split[0]
			@data=[] 
		end
		@data<<{backend=>data}.dup
		p @data.count
		@config['server']['log_format'].split.each do |format|
			log_file=File.open(@config['server']['log']+"."+format,'w+')
			case format
			when 'hex'
				log_file.puts @data.to_s.unpack('H*')[0].to_s
			when 'json'
				#to_json存在编码的问题，不明确指明编码可能会导致问题，php语言的json-encode只支持utf8，所以就默认设定为utf8了
				log_file.puts @data.to_json
			when 'yaml'
				log_file.puts @data.to_yaml
			when 'raw'
				log_file.puts @data
			end
		end
		log_file.flush
		log_file.close
	end

	def config
		config={"server"=>{"ip"=>'0.0.0.0','port'=>'8077', 'log'=>'proxy.log', 'log_encoding'=>'UTF-8', 'log_format'=>'json yaml raw', 'encoding'=>'GBK'},'forward'=>{'baidu1'=>{"host"=>'www.baidu.com',"port"=>'80','encoding'=>'GBK'},'baidu2'=>{"host"=>'www.baidu.com',"port"=>'80','encoding'=>'GBK'}}}
		File.open("proxy.conf",'w') do |f|
			f.puts config.to_yaml
		end
		puts "proxy.conf OK"
	end

	def run(conn)
		@config['forward'].each do |k,v|
			conn.server k, :host =>v['host'], :port =>v['port']
		end
		# modify / process request stream
		conn.on_data do |data|
			log 'req',data
			data
		end
		# modify / process response stream
		conn.on_response do |backend, resp|			
			log backend, resp
			#需要增加多转发时候的请求销毁
			resp
		end

		# termination logic
		conn.on_finish do |backend, name|
			# terminate connection (in duplex mode, you can terminate when prod is done)
			# unbind if backend == :srv
		end
	end

	def start(debug,config_file='proxy.conf')
		@config=YAML::load IO.read(config_file)
		@data=[]
		#ruby的一个问题，@config 无法传入到block中，但是config可以，主要是上下文有关，采用迂回的方法回调
		puts "port: #{@config['server']['port']}"
		server=self
		Proxy.start(:host => @config['server']['ip'], :port => @config['server']['port'], :debug => debug ) do |conn|
			server.run(conn)
		end

	end
end


if __FILE__==$0
	server=ProxyServer.new
	case ARGV[0]
	when 'config'
		server.config
	when 'help'
		server.help
	when nil
		server.help
	when 'start'
		debug=true if ARGV[1]=='debug'
		server.start(debug)
	end

end


