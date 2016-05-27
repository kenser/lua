local _M = {}


function _M:string_split(s, p)
  local rt= {}
  string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
  return rt
end



function _M:readfileforshm(file,shm)
	local file = assert(io.open(file, "r"))
		
    while true do
		line = file:read("*line")
		if line == nil then break end
		
		line = tostring(line);
		
		line=string.gsub(line,'#.*', '')
		line=string.gsub(line,'\t', '')
		line=string.gsub(line,' ', '')
		line=string.gsub(line,'\n', '')
		line=string.gsub(line,'\r', '') ---for window
		
		if line ~= nil and line ~= '' then
			--ngx.say(line)
			local success, err, forcible = shm:set(line,1)
			if not success then
				ngx.log(ngx.ERR, '[EMO-LUA] nginx dict set error, ', err)
			end
			--local mesg = line..'-'..shm:get(line)
			--ngx.say(mesg)
		end
		
	end
	
	file:close()

end


function _M:readfileforuri(file,shm)
	local file = assert(io.open(file, "r"))
		
    while true do
		line = file:read("*line")
		if line == nil then break end
		
		line = tostring(line);
		
		line=string.gsub(line,'#.*', '')
		line=string.gsub(line,'\t', '')
		line=string.gsub(line,' ', '')
		line=string.gsub(line,'\n', '')
		line=string.gsub(line,'\r', '') ---for window
		
		if line ~= nil and line ~= '' and line~='?' then
			--add script
			local key
			local args
			local pos = string.find(line,'?')
			if pos == nil then 
				key = line
				args = ''
			else
				key = string.sub(line,1,pos-1)
				if pos == #line then 
					args=''
				else
					args=line.sub(line,pos+1)
				end
				
			end
			--add args
			if args == '' then 
				args = {}
			else
				args = self:string_split(args, '&')
				local tmp_arg = {}
				for i, v in ipairs(args) do
					local tem_list = self:string_split(v, '=')
					if #tem_list == 2 then
						tmp_arg[tem_list[1]] =tem_list[2]
					end
					--tmp_arg = {tmp_arg}
				end
				args = tmp_arg
			end
			
			local index = string.find(line,'/')
			if index == nil or index ~=1 then
				key = '/'..key
			end
			local value = shm:get(key)
			
			if value ~=nil then
				value = cjson.decode(value)
				table.insert(value, args)
				args = value
			else
				args ={ args }
			end
			
			args = cjson.encode(args)
			local success, err, forcible = shm:set(key,args)
			if not success then
				ngx.log(ngx.ERR, '[EMO-LUA] nginx dict set error, ', err)
			end
			
		end
		
	end
	
	file:close()

end


return _M