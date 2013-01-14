#encoding: gbk
require 'json';
p '12中国'.force_encoding('GBK').to_json
p '12中国'.force_encoding('UTF-8').to_json
p JSON::encode('12中国')
p '12中国'.force_encoding('US-ASCII').to_json
p '12中国'.force_encoding('ASCII-8BIT').to_json
