count = count + 1  
ngx.say("global variable : ", count)  
local shared_data = ngx.shared.shared_data  
ngx.say(", shared memory : ", shared_data:get("count"))  
shared_data:incr("count", 1)  
ngx.say("<a>hello world</a><br>ip:"..ngx.var.remote_addr..'<br>')  