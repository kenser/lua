if not LUA_MAIN_SWITCH or LUA_MAIN_SWITCH ~= 'ON' then return end

if not TIMER_DELAY then return end

local now_time = ngx.time()
local delay = TIMER_DELAY
local new_timer = ngx.timer.at
local log = ngx.log
local ERR = ngx.ERR
local check,clean_log
local filename = LOG_PATH..LOG_NAME

clean_log = function()
	local last_time = ngx.shared.dt_config:get("log_last_time")
	
	if not last_time or last_time == 0 then return end
	
	local dura = ngx.time() - last_time
	if dura < 2*delay then return end
	
	local f=assert(io.open(filename,"w+"))
	f:close()
	
	ngx.shared.dt_config:set("log_last_time",0)
	ngx.shared.dt_config:set("log_last_clean_time",ngx.time())
end

check = function(premature)
	if not premature then
		clean_log()
		local ok, err = new_timer(delay, check)
		if not ok then
			log(ERR, "failed to create timer: ", err)
			return
		end
	end
end

local ok, err = new_timer(delay, check)
if not ok then
	log(ERR, "failed to create timer: ", err)
	return
end
