--require  and  loadfile to shm
require("config.config")
cjson = require("cjson")
local readfile = require("common.readfile")
cookie = require('common.cookie')
--preload in init 
require('common.util')
require('common.count')
require('common.strategy')
redis = require("cache.redis")


  
ngx.shared.dt_ip_whitelist:flush_all()
ngx.shared.dt_ip_blacklist:flush_all()
ngx.shared.dt_uri_whitelist:flush_all()
ngx.shared.dt_uri_blacklist:flush_all()

ngx.shared.dt_st_ip:flush_all()
ngx.shared.dt_st_ip_uri:flush_all()
ngx.shared.dt_st_ip_log:flush_all()



ngx.shared.dt_st_web:flush_all()
ngx.shared.dt_uri:flush_all()

ngx.shared.dt_config:flush_all()

ngx.shared.dt_intelligent_ban_ip_list:flush_all()
ngx.shared.dt_intelligent_ban_uri_list:flush_all()
ngx.shared.dt_intelligent_ban_ip_uri_list:flush_all()
---add switch
if not LUA_MAIN_SWITCH or LUA_MAIN_SWITCH ~= 'ON' then return end

if IP_WHITE_LIST_SWITCH == "ON" then
	local filename = ROOT_PATH..'lua/config/ip_whitelist'
	readfile:readfileforshm(filename,ngx.shared.dt_ip_whitelist)
end


if IP_BLACK_LIST_SWITCH == "ON" then
	local filename = ROOT_PATH..'lua/config/ip_blacklist'
	readfile:readfileforshm(filename,ngx.shared.dt_ip_blacklist)
end

--uri  b and w
if URI_BLACK_LIST_SWITCH == "ON" then
	local filename = ROOT_PATH..'lua/config/uri_blacklist'
	readfile:readfileforuri(filename,ngx.shared.dt_uri_blacklist)
end


if URI_WHITE_LIST_SWITCH == "ON" then
	local filename = ROOT_PATH..'lua/config/ip_whitelist'
	readfile:readfileforshm(filename,ngx.shared.dt_uri_whitelist)
end


--ansys uri
local filename = ROOT_PATH..'lua/config/statistics_uri'
readfile:readfileforuri(filename,ngx.shared.dt_uri)
