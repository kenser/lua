LUA_MAIN_SWITCH = "ON"


LOG_PATH = '/usr/servers/nginx/conf/lua/log/'


--ip_white_list

IP_WHITE_LIST_SWITCH = "ON"

URI_WHITE_LIST_SWITCH = "ON"

URI_BLACK_LIST_SWITCH = "ON"

IP_BLACK_LIST_SWITCH = "ON"

IP_COUNT = "ON"

IP_URI_COUNT = "ON"

URI_COUNT = "ON"


ORDER = {'ip_whitelist','uri_whitelist','ip_blacklist','uri_blacklist',}


ROOT_PATH = '/usr/servers/nginx/conf/'


LOG_NAME = 'log_message'

TIMER_DELAY = 60


DEFAULT_DURATION = 2
DEFAULT_COUNT = 2
DEFAULT_TIMES = 2


IGNORE_STATISTICS_TYPE = {
	'css','js','png','gif','jpg',
}

--redis : ip and port
HOST_NAME = '127.0.0.1'
HOST_PORT = 6379


PRE_KEY = 'BAN_LIST_'


-- expire : 2 hour
BAN_EXPIRE = 60
--- 2 days
LOG_EXPIRE = 2

LOG_PRE = 'emo_log_'

TIME_CONTROL = { 
	switch = 'ON',
	control = {
	{starttime = 1,endtime = 24, ban_type = 'ip',duration=3, count=1000, times = 3},
	{starttime = 0,endtime = 24, ban_type = 'ip_uri',duration=3, count=1000, times = 3},
	{starttime = 0,endtime = 24, ban_type = 'uri',duration=3,count=1000, times = 3},
	}
}


THRESHOLD = {
	switch = 'ON',
	strategy = {
	{threshold = 50000 ,ban_type = 'ip',duration=3, count=10000, times = 2},
	{threshold = 20000 ,ban_type = 'ip_uri',duration=3, count=10000, times = 5},
	{threshold = 30000 ,ban_type = 'uri',duration=3, count=100,times = 5},
	}
}


WARN_LOG = {
	switch = 'ON',
	ip = {duration=5, mincount=1, maxcount=3000,times = 2, is_intelligent_ban = true},
	cookie = {duration=2, mincount=1, maxcount=30000,times = 2, is_intelligent_ban = true},
	ip_uri = {duration=10, mincount=1, maxcount=50000,times = 2, is_intelligent_ban = true},
}

DEFAULT_ROUTE_IP = 'proxycn'

ROUTE = {
	switch = 'ON',
	uri = {
		forum ={'mod=viewthread&tid=20?192.168.24.45:8088'},
		home = {'*?192.168.24.45:8088'},
		
	}
}
