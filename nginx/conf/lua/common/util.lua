local _M = {}


function _M:clear_st_dict()

ngx.shared.dt_st_ip:flush_all()
ngx.shared.dt_st_cookie:flush_all()

end

function _M:clear_list_dict()

ngx.shared.dt_ip_whitelist:flush_all()

end

function _M:check_st_type()
	if not IGNORE_STATISTICS_TYPE then return 0 end
	local req = ngx.var.uri
	if req and req =='/' then return 0 end
	if not req then return 0 end
	local st = IGNORE_STATISTICS_TYPE
	
	local flag = false
	if type(st) == 'table' and #st >0 then
		for i,v in pairs(st) do
			v = '.'..v
			local count = #v
			if #req > count then
				if string.sub(req,-count) == v then flag = true end
			end
		end
	end
	
	if flag == true then 
		return 1
	else
		return 0
	end
end


function _M:check_config_access(ip,in_b,in_w)
	local access = 0
	if type(ORDER) == 'table' and #ORDER > 0 then
		for i ,v in ipairs(ORDER) do
			local result = self:switch_order(v,ip,in_b,in_w)
			if result == 1 or result == 2 then
				access = result
				break
			end
		end
	end
	return access

end
-- 1 access ,2 forbbiden  ,0 go on
function _M:switch_order(key,ip,in_b,in_w)

	local ip_wlist = function() 
		local result = ngx.shared.dt_ip_whitelist:get(ip) 
		if result==1 then return 1 else return 0 end
	end
	
	local ip_blist = function() 
		local result = ngx.shared.dt_ip_blacklist:get(ip)
		if result==1 then return 2 else return 0 end
	end
	local uri_wlist = function() 
		local result = ngx.shared.dt_uri_whitelist:get(ip) 
		if result==1 then return 1 else return 0 end
	end
	local uri_blist = function() 
		local result = ngx.shared.dt_uri_blacklist:get(ip)
		if result==1 then return 2 else return 0 end
	end
	
	
	local list= {
	ip_whitelist = ip_wlist,
	uri_whitelist = uri_wlist,
	ip_blacklist = ip_blist,
	uri_blacklist = uri_blist,
	}
	
	if list[key] == nil then return 0 end
	return list[key]()

end


function _M:check_banlist_access_ip(ip)

	local ip_key = PRE_KEY..ip
	
	local result = self:get_ban_to_cache(ip_key)
        	--ngx.say(result)
	if result =='1' then 
		return 2
	elseif not result  then
		local ipset = ngx.shared.dt_intelligent_ban_ip_list:get(ip)
		if ipset==1 then return 2  end
	end
	
	
	return 0
--[[

	local result = ngx.shared.dt_intelligent_ban_ip_list:get(ip)
	if result==1 then return 2  end
	
	local result = ngx.shared.dt_intelligent_ban_cookie_list:get(cookie)
	if result==1 then return 2  end
	
	return 0
]]
end

function _M:check_banlist_access_uri(uri)

	local uri_key = PRE_KEY..uri
	
	local result = self:get_ban_to_cache(uri_key)
        	--ngx.say(result)
	if result =='1' then 
		return 2
	elseif not result  then
		local uriset = ngx.shared.dt_intelligent_ban_uri_list:get(uri)
		if uriset==1 then return 2  end
	end
	
	
	return 0
end

function _M:check_banlist_access_ip_uri(ip_uri)

	local ip_uri_key = PRE_KEY..ip_uri
	
	local result = self:get_ban_to_cache(ip_uri_key)
        	--ngx.say(result)
	if result =='1' then 
		return 2
	elseif not result  then
		local uriset = ngx.shared.dt_intelligent_ban_ip_uri_list:get(ip_uri)
		if uriset==1 then return 2  end
	end
	
	
	return 0
end

function _M:get_cache_handle()
	
	
	
	--return red

end


function _M:close_cache_handle(handle)
	
	local ok, err = handle:set_keepalive(60000, 10)
	if not ok then
		--ngx.say("failed to set keepalive: ", err)
		return false
	end
	
	return true
end



function _M:set_ban_to_cache(key,value,exptime)
	if type(key) ~='string' or key=='' then return false end
	if type(HOST_NAME) ~='string' or HOST_NAME=='' then return false end
	if type(HOST_PORT) ~='number' or HOST_PORT==0 then return false end
	
	local red = redis:new()

	red:set_timeout(1000) -- 1 sec

	local ok, err = red:connect(HOST_NAME, HOST_PORT)
	if not ok then
		--ngx.say("failed to connect: ", err)
		return nil
	end
	
	
	local ok
	local err
	if type(exptime) == 'number' and exptime>0 then
		ok, err = red:setex(key, exptime,value)
	else
		ok, err = red:set(key, value)
	end
	--self:close_cache_handle(red)
	
	if not ok then
		--ngx.say("failed to set key: ", err)
		return false
	end
	
	local ok, err = red:set_keepalive(60000, 50)
	if not ok then
		--ngx.say("failed to set keepalive: ", err)
		return false
	end
	
	return ok


end

function _M:get_ban_to_cache(key)
	
	if type(key) ~='string' or key=='' then return false end
	if type(HOST_NAME) ~='string' or HOST_NAME=='' then return false end
	if type(HOST_PORT) ~='number' or HOST_PORT==0 then return false end
	
	local red = redis:new()

	red:set_timeout(1000) -- 1 sec

	local ok, err = red:connect(HOST_NAME, HOST_PORT)
	if not ok then
		--ngx.say("failed to connect: ", err)
		return nil
	end
	

	local res, err = red:get(key)
	
	if not res then
		--ngx.say("failed to get key: ", err)
		return false
	end
	
	local ok, err = red:set_keepalive(60000, 50)
	if not ok then
		--ngx.say("failed to set keepalive: ", err)
		return false
	end
	
	return res
	
end

function _M:printdict(dict)
	local keys = dict:get_keys(2048)
	
	for k ,v in ipairs(keys) do
		
		ngx.say(v..'::'..dict:get(v))
	end
end

function _M:clear_to_cache(dict)
	local keys = dict:get_keys(2048)
	local red = redis:new()

	red:set_timeout(1000) -- 1 sec

	local ok, err = red:connect(HOST_NAME, HOST_PORT)
	if not ok then
		--ngx.say("failed to connect: ", err)
		return nil
	end
	
	--local red = self:get_cache_handle()
	
	--if red ==nil then return false end
	
	for k ,v in ipairs(keys) do
		local key = PRE_KEY..v
		local ok, err = red:setex(key,1, 0)
		--red:setex('emo_log_'..v,1, 0)
		--ngx.say(PRE_KEY..v..'::'..dict:get(v))
	end
	local ok, err = red:set_keepalive(60000, 50)
	if not ok then
		--ngx.say("failed to set keepalive: ", err)
		return false
	end
	
end

function _M:clear_log_set(key)
	local red = redis:new()

	red:set_timeout(1000) -- 1 sec

	local ok, err = red:connect(HOST_NAME, HOST_PORT)
	if not ok then
		--ngx.say("failed to connect: ", err)
		return nil
	end
	
	red:setex(LOG_PRE..key,1, 0)
	
	red:set_keepalive(60000, 50)

end
return _M
