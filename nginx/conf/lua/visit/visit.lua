
if not LUA_MAIN_SWITCH or LUA_MAIN_SWITCH ~= 'ON' then
	ngx.say('LUA_MAIN_SWITCH   OFF ,please change it ,and reload nginx')
	return 
end

local util = require('common.util')

local args = ngx.req.get_uri_args()
if args['type'] == 'ip' then


	if args['delete'] == 'all' then
		util:clear_to_cache(ngx.shared.dt_intelligent_ban_ip_list)
		ngx.shared.dt_intelligent_ban_ip_list:flush_all()
	elseif type(args['delete']) =='string' and args['delete'] ~=nil    then 
		util:set_ban_to_cache(PRE_KEY..args['delete'],0,1)
		ngx.shared.dt_intelligent_ban_ip_list:delete(args['delete'])
		if  args['clear_log']  and args['clear_log'] == '1' then
			util:clear_log_set(args['delete'])
		end
	end

	util:printdict(ngx.shared.dt_intelligent_ban_ip_list)
end

if args['type'] == 'cookie' then
	
	
	if args['delete'] == 'all' then
		util:clear_to_cache(ngx.shared.dt_intelligent_ban_cookie_list)
		ngx.shared.dt_intelligent_ban_cookie_list:flush_all()
	elseif type(args['delete']) =='string' and args['delete'] ~=nil    then 
		util:set_ban_to_cache(PRE_KEY..ngx.var.arg_delete,0,1)
		ngx.shared.dt_intelligent_ban_cookie_list:delete(ngx.var.arg_delete)
		if  args['clear_log']  and args['clear_log'] == '1' then
			util:clear_log_set(ngx.var.arg_delete)
		end
	end
	
	ngx.say('cookie:')
	util:printdict(ngx.shared.dt_intelligent_ban_cookie_list)
end


ngx.say('hello,')
