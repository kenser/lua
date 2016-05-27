local _M = {}



function _M:check_strategy(key)
	local result = {activate = false}
	
	--check threashold ,THRESHOLD.strategy
	local dict = ngx.shared.dt_config
	local current_threshold =  dict:get('threshold')
	if current_threshold ~= nil and current_threshold>0 then
		result = self:check_threshold_strategy(THRESHOLD,current_threshold,key)
	end
	
	--check time  TIME_CONTROL
	if result.activate == nil or not result.activate then
		result = self:check_time_strategy(TIME_CONTROL,key)
	end
	
	
	-- return drua times count  ischange
	return result
end

function _M:check_time_strategy(time_config,key)
	local now = os.date("%H.%M", ngx.time())
	now  = tonumber(now)
	
	local result = {activate = false}
	
	if type(time_config.switch) ~= 'string' or  time_config.switch ~='ON' then return result end
	
	if type(time_config.control) == 'table' and time_config.control~=nil then
		for i,v in ipairs(time_config.control) do
			if now >v.starttime and now < v.endtime and v.duration>0 and v.count>0 and v.times >0 and key == v.ban_type then
				result.activate = true
				result.duration = v.duration
				result.sum = v.count
				result.times = v.times
				result.ban_type = v.ban_type
				result.type = 'time'
				break
			
			end
		end
	end

	return result

end


function _M:check_threshold_strategy(threshold_config,current_threshold,key)
	local result = {activate = false}
	
	if type(threshold_config.switch) ~= 'string' or  threshold_config.switch ~='ON' then return result end
	
	local list = threshold_config.strategy
	if type(list) == 'table' and list~=nil then
		for i,v in ipairs(list) do
			if v.threshold >0 and  current_threshold > v.threshold and v.duration>0 and v.count>0 and v.times >0 and key == v.ban_type then
				result.activate = true
				result.duration = v.duration
				result.sum = v.count
				result.times = v.times
				result.ban_type = v.ban_type
				result.type = 'threshold'
				break
			end
		end
	end
	
	return result
end


function _M:check_strategy_ischange(dict)
	


end





return _M