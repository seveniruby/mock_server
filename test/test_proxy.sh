jruby ../bin/proxy.rb config
sleep 1
jruby ../bin/proxy.rb start &
pid=$!
sleep 2
curl -x 127.0.0.1:8077 'http://www.baidu.com' > /dev/null
sleep 10
rm proxy.log.*.bak
for f in proxy.log.*
do
	mv $f $f.bak
done
ls -l proxy.log*
sleep 2
curl -x 127.0.0.1:8077 'http://www.baidu.com' >/dev/null
sleep 1
ls -l  proxy.log*
kill $pid
