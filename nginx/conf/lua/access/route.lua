function string_split(s, p)
  local rt= {}
  string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
  return rt
end

function get_script_name(uri)
	local index,total ,rt = string.find(uri,'/([%-%_%a%d%.]*)$')
	return rt
end

function get_var_comp(str)
	local rt = {}
	
	local total = 0
	local list = string_split(str, '&')
	for i,v in pairs(list) do
		local tmp = string_split(v, '=')
		if #tmp == 2 then
			rt[tmp[1]] = tmp[2]
			total = total+1
		end
	
	end
	
	return rt,total

end

function  test_var_comp(args)
	local total = 0
	local matchs = 0
	if type(args) == 'table'  then
		local list= ngx.req.get_uri_args()
		for k,v in pairs(args) do
			if list[k] and (list[k] == v  or v == '*') then matchs = matchs+1 end
			total = total+1
		end
		
	end
	--ngx.log(ngx.WARN,'[LUA]total:'..total)
	--ngx.log(ngx.WARN,'[LUA]matchs:'..matchs)
	
	return  total == matchs

end
---- resure default not nil
local default_up_stream = DEFAULT_ROUTE_IP

---add switch
if not LUA_MAIN_SWITCH or LUA_MAIN_SWITCH ~= 'ON' then return DEFAULT_ROUTE_IP end

if ROUTE and ROUTE.switch and ROUTE.switch == 'ON' and ROUTE.uri then

	local ru = ROUTE.uri
	local req = ngx.var.uri
	local script_name = get_script_name(req)
	
	if '.php' == string.sub(script_name,-4)   then
		script_name = string.sub(script_name,1,-5)
	elseif '.html' == string.sub(script_name,-5) then
		script_name = string.sub(script_name,1,-6)
	end

	if script_name and ru[script_name] then
		for i,v in pairs(ru[script_name]) do
			local items = string_split(v, '?')	
			if #items == 2 then
				local ip = items[2]
				local str = items[1]
				local comps,total = get_var_comp(str)
	
				if (total >0 and test_var_comp(comps)) or total ==0  then
					default_up_stream = ip
					break
				end
			end
		end
	end

end



return default_up_stream