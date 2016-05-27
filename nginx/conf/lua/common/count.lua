--local cjson = require('cjson')
local _M = {}
_M.timeout = 0
_M.maxcount = 0
_M.sum = 0
_M.ban_type = ''

function _M:new(timeout,maxcount,sum,ban_type)
	self.timeout = tonumber(timeout)
	self.maxcount = tonumber(maxcount)
	self.sum = tonumber(sum)
	self.ban_type = tostring(ban_type)
end

function _M:count(key , dict)
	
	if self.timeout == nil or self.maxcount==nil or self.timeout <= 0 or self.maxcount<=0 then 
		--ngx.log(ngx.WARN,'[lua]--------statistics failed----- :timeout=0 or maxcount =0 ')
		return nil
	end
	
	
	local value,err = dict:get(key)
       -- ngx.say(value)
	local tmp
	local now = ngx.now()
	
	if value == nil then 
		value = {}
		value.starttime = now
		value.endtime = now
		value.count = 1
		value.history = {}
		--tmp = cjson.encode({starttime = now,endtime = now,count = 1,history={}})
	else
		value = cjson.decode(value)
		value.count = value.count+1
		value.endtime = now
		
		-- if timeout ,reset and add history
		if now - value.starttime > self.timeout  then
			--add history
			value.history = self:add_history(value.history,value.count,self.maxcount)
			-- if now - value.starttime> 2* self.timeout  add  0
			if now - value.starttime> 2*(self.timeout) then
				value.history = self:add_history(value.history,0,self.maxcount)
			end
			--reset
			value.starttime = now
			value.count = 0
		end

	end
	
	tmp = cjson.encode(value)
        --ngx.say("count"..tmp)	
	local success, err, forcible = dict:set(key, tmp)
      --ngx.say(dict:get(key))
	if not success then
		ngx.log(ngx.WARN,'[LUA]set count failed :'..err)
	end
	return value.history
end

function _M:add_history(arr ,sum,maxcount)
	local history_num = #(arr)
	local maxcount = maxcount
	local tmp = arr
	if  history_num == 0 or maxcount ==1 then
		arr[1] = sum
	elseif history_num < maxcount  then
		arr[history_num+1] = sum 
	elseif history_num  == maxcount	then 
		for i,v in ipairs(arr) do 
			if i == maxcount then break end
			arr[i] = arr[i+1]
		end
		arr[maxcount] = sum
	else
		arr= {}
	end
	
	return arr
end

function _M:add_detail(key,dict,sum)
	local value = dict:get(key)
	local tmp
	if value == nil then
		tmp = cjson.encode({sum})
	else
	
		local list = cjson.decode(value)
		local index = #list
		
		if index < maxcount and index~=0 then
			list[index+1] = sum
		elseif index ==0 then
			list[1] = sum
		else
			for i,v in ipairs(list) do 
				if list[i+1] == nil then break end
				list[i] = list[i+1]
			end 
			list[maxcount] = sum
		end
		
		tmp = cjson.encode(list)
		--for i,v in ipairs(list) do end  
	end
	
	local success, err, forcible = dict:set(key, tmp)
	if not success then
		ngx.log(ngx.WARN,'[LUA]set '..key..' failed :'..err)
	end
	
end

function _M:count_web(dict,config_dict)
	local list = self:count('web_count',dict)
	local num = #list
	if #list == self.maxcount and  self.maxcount >0  then
		local sum = 0
		for i,v in pairs(list) do
			sum = sum + (v+0)
		end
		
		local avg = sum/num
		config_dict:set('threshold',avg)
		
	end
	
end

function _M:ban_to_cache(key,value)
	local ut = require('common.util')
	ut:set_ban_to_cache(key,value,BAN_EXPIRE)


end


function _M:count_ban(key,dict,intelligent_ban_dict,bantype)
	if key == nil or key == '' then return end
	
	local list = self:count(key,dict)

	if type(list) == 'table' and #list == self.maxcount and  self.maxcount >0 and (self.ban_type == bantype or self.ban_type == 'all') and self.sum>0  then
		local flag = true
		for i,v in pairs(list) do
			if self.sum > v then flag = false end  
		end
		--ngx.say(flag)
		if flag then
			intelligent_ban_dict:set(key,1,BAN_EXPIRE)
			self:ban_to_cache(PRE_KEY..key,1)
		end
	end
	
	
	
end


function _M:count_warn(key,dict,intelligent_ban_dict,bantype,bankey)
	if key == nil or key == ''  or bankey == nil then return end
	--ngx.say(bantype)
	local log_config = WARN_LOG[bantype]
--        ngx.say(log_config.maxcount)     
	if type(log_config) == 'table' and log_config.mincount>0 and log_config.maxcount>0 then
                
		self:new(log_config.duration,log_config.times ,0,bantype)
		local list = self:count(key,dict)
               -- ngx.say(#list)
		if  type(list) == 'table'  and #list == self.maxcount and  self.maxcount >0 then
         		local sum = 0
			local min_sum = 0
			local max_sum = 0
			for i,v in pairs(list) do
				if v and v >= log_config.mincount and v < log_config.maxcount then min_sum = min_sum+1 end
				if v and v >= log_config.maxcount then max_sum = max_sum+1 end
				--sum = sum + (v+0)
			end
			if min_sum == #list   then 
				self:writelog(key,1,bantype)
			elseif max_sum == #list then
				if log_config.is_intelligent_ban then
					intelligent_ban_dict:set(bankey,1,BAN_EXPIRE)
					self:ban_to_cache(PRE_KEY..bankey,1)
				end
				self:writelog(key,2,bantype)
			elseif  min_sum >0 and min_sum+max_sum == #list then
				self:writelog(key,1,bantype)
			end
                        
		end
		
	end
	
end

function _M:writelog(key,value,bantype)
	--sdv3  add once to log
	if key == nil or key == '' or not bantype  then return end
	
	if LOG_PRE and LOG_EXPIRE and LOG_EXPIRE >0 then
		local ut = require('common.util')
		local pre = LOG_PRE
		local result = ut:get_ban_to_cache(pre..key)
		result = tonumber(result)
		value = tonumber(value)
		if result and value  and result>0 and result >= value then
			return
		end
		-- default 2 days
		local expire = LOG_EXPIRE
		ut:set_ban_to_cache(pre..key,value,expire)
	end
	
	
	local now = os.date("%Y%m%d%H%M%S", ngx.time())
	local fixname = 'emo_log_'..bantype..'_'..value
	local filename = LOG_PATH..fixname
	local f=assert(io.open(filename,"a+"))
	local line = key.."\t"..value.."\t"..now
	f:write(line.."\n")
	f:close()
	
	
	--append log_message
	local last_clean_time = ngx.shared.dt_config:get("log_last_clean_time")
	if not last_clean_time  or (ngx.time() - last_clean_time) > 2*TIMER_DELAY then
		local log_name = LOG_PATH..LOG_NAME
		local fh=assert(io.open(log_name,"a+"))
		local message = "[message from huafans]"..key..":"..value
		fh:write(message.."\n")
		fh:close()
	end
	
	---append log_write_time 
	local last_time = ngx.shared.dt_config:get("log_last_time")
	if not last_time or last_time==0 then 
		 ngx.shared.dt_config:set("log_last_time",ngx.time())
	end
	
end

--

function _M:check_uri_inlist(uri,args,dict)
	local dict = dict--ngx.shared.dt_uri
	local key = uri
	local list = dict:get(key)
	local flags = false
	local args = args
	if list ~= nil then
		list = cjson.decode(list)
		if #list == 0 then 
			flags = true
		else
			key = key..'?'
			for i,v in pairs(list) do
				local ex = 0
				local num = 0
				for k,m in pairs(v) do
					if args[k] == m  or (m == '*' and args[k]~=nil) then
						ex = ex+1
						key = key..'&'..k..'='..m
					end
					num = num+1
				end
				--all match then break
				if ex == num then
					flags = true
					break
				end
			end
		end
		
	end 
	return key,flags

end

return _M
