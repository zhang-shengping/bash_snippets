ps -ef | grep parallel | grep -v grep |  cut -c 9-16 | xargs kill -s 9
