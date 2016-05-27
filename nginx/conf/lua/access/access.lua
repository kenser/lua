
if not LUA_MAIN_SWITCH or LUA_MAIN_SWITCH ~= 'ON' then return end

local statistics = require('common.count')
local util = require('common.util')
local strategy = require('common.strategy')

local ip = ngx.var.remote_addr
local uri = ngx.var.uri

local timeout = 0
local maxcount = 0
local sum = 0
local ban_type = "all"

local _, in_whitelist =  statistics:check_uri_inlist(ngx.var.uri,ngx.req.get_uri_args(),ngx.shared.dt_uri_whitelist)

local _, in_blacklist =  statistics:check_uri_inlist(ngx.var.uri,ngx.req.get_uri_args(),ngx.shared.dt_uri_blacklist)

local result = util:check_config_access(ip,in_blacklist,in_whitelist)

if result == 2 then
	ngx.exit(ngx.HTTP_FORBIDDEN)
	return
elseif result == 1 then
	return
else 
	local banlist_ip = util:check_banlist_access_ip(ip)
	if  banlist_ip == 2 then
		ngx.exit(ngx.HTTP_FORBIDDEN)
		return
	end
end

local result_uri = util:check_config_access(uri,in_blacklist,in_whitelist)
if result_uri == 2 then
	ngx.exit(ngx.HTTP_FORBIDDEN)
	return
elseif result_uri == 1 then
	return
else 
	local banlist_uri = util:check_banlist_access_uri(uri)
	if  banlist_uri == 2 then
		ngx.exit(ngx.HTTP_FORBIDDEN)
		return
	end
end

local banlist_ip_uri = util:check_banlist_access_ip_uri(ip..uri)
	if  banlist_ip_uri == 2 then
		ngx.exit(ngx.HTTP_FORBIDDEN)
		return
	end
---check type
local re = util:check_st_type()	
if re == 1 then return end

if  IP_COUNT and IP_COUNT == 'ON' then 
--获取 配置文件 中的策略. 根据 策略 来统计 数据，智能封ip cookie

        if uri == '/luua' and IP_URI_COUNT and IP_URI_COUNT == 'ON' then
            local result = strategy:check_strategy('ip_uri')
			--ngx.say(result.ban_type..result.sum )
			if result ~= nil and result.activate  then
				timeout = result.duration 
				sum = result.sum 
				maxcount = result.times 
				ban_type = result.ban_type
				
			
			else
				util:clear_st_dict()
			end


			statistics:new(timeout,maxcount,sum,ban_type)
			--ip
			statistics:count_ban(ip..uri, ngx.shared.dt_st_ip,ngx.shared.dt_intelligent_ban_ip_list,'ip_uri')

			--uri
			local key,flags = statistics:check_uri_inlist(ngx.var.uri,ngx.req.get_uri_args(),ngx.shared.dt_uri)
			if flags then
				
				statistics:count_warn(ip..'_'..key, ngx.shared.dt_st_ip_uri,ngx.shared.dt_intelligent_ban_ip_list,'ip_uri',ip)
			end
        end
		local result = strategy:check_strategy('ip')
		--ngx.say(result.ban_type..result.sum )
		if result ~= nil and result.activate  then
			timeout = result.duration 
			sum = result.sum 
			maxcount = result.times 
			ban_type = result.ban_type
			
		
		else
			util:clear_st_dict()
		end


		statistics:new(timeout,maxcount,sum,ban_type)
		--ip
		statistics:count_ban(ip, ngx.shared.dt_st_ip,ngx.shared.dt_intelligent_ban_ip_list,'ip')

		if type(WARN_LOG.switch) ~= 'string' or  WARN_LOG.switch~= 'ON' then return end

		--ip
		statistics:count_warn(ip, ngx.shared.dt_st_ip_log,ngx.shared.dt_intelligent_ban_ip_list,'ip',ip)
		

 end

if URI_COUNT and URI_COUNT == 'ON' and ngx.shared.dt_uri:get(uri) then 

	local result = strategy:check_strategy('uri')
		--ngx.say(result.ban_type..result.sum )
		if result ~= nil and result.activate  then
			timeout = result.duration 
			sum = result.sum 
			maxcount = result.times 
			ban_type = result.ban_type
			
		
		else
			util:clear_st_dict()
		end

	statistics:new(timeout,maxcount,sum,ban_type)
	--uri
	statistics:count_ban(uri, ngx.shared.dt_st_uri,ngx.shared.dt_intelligent_ban_uri_list,'uri')

	if type(WARN_LOG.switch) ~= 'string' or  WARN_LOG.switch~= 'ON' then return end

		--warn
		statistics:count_warn(uri, ngx.shared.dt_st_uri_log,ngx.shared.dt_intelligent_ban_uri_list,'uri',uri)

 end