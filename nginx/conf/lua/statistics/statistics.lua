
if not LUA_MAIN_SWITCH or LUA_MAIN_SWITCH ~= 'ON' then return end

-- web ， ip ， cookie， uri，ip+uri,cookie+uri
local ut = require('common.util')
local statistics = require('common.count')

local timeout = DEFAULT_DURATION
local maxcount = DEFAULT_TIMES
local sum = 0
local ban_type = "all"
local ip = ngx.var.remote_addr

---check type
local re = ut:check_st_type()	
if re == 1 then return end

--web 作为阀值监控，不受控制 ,自动向config中添加当前 5次的平均阀值
statistics:new(timeout,maxcount,sum,ban_type)
statistics:count_web(ngx.shared.dt_st_web,ngx.shared.dt_config)
