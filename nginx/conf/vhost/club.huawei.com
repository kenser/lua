server{
    access_by_lua_file /usr/servers/nginx/conf/lua/access/access.lua;
	listen 8082 ;
	server_name club.huawei.com ;
	#access_log /data/www/logs/club.huawei.com-access_log main;
	#error_log /data/www/logs/club.huawei.com-error_log  warn;
	#root /data/www/huawei/branch;
	location /luua {
	lua_code_cache on;
         default_type 'text/html';  
        content_by_lua_file conf/lua/test.lua;    
        }
    location /lua_config {
	     lua_code_cache on;
         default_type 'text/html';  
         content_by_lua_file conf/lua/test.lua;  
        }
}
