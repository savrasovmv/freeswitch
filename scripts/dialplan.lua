-- Определение направления в диалплане

pathsep = '/'
freeswitch.consoleLog("notice","Определение направления в диалплане")

local req_destination_number   = session:getVariable("destination_number");
local req_domain   = session:getVariable("domain");
local caller_id_number   = session:getVariable("caller_id_number");
local gateway_var_name   = session:getVariable("gateway_var_name");
freeswitch.consoleLog("INFO", "req_destination_number: " .. req_destination_number .. "\n")
freeswitch.consoleLog("INFO", "req_domain: " .. req_domain .. "\n")
freeswitch.consoleLog("INFO", "caller_id_number: " .. caller_id_number .. "\n")
freeswitch.consoleLog("INFO", "gateway_var_name: " .. gateway_var_name .. "\n")

local db = require("db")
dbh = db.connect()
local isFinish = 0
function direction(sql_query, lua_script_name)

    assert (
        dbh:query(sql_query, 
            function(u)  
                freeswitch.consoleLog("INFO", "SATART "..lua_script_name.." script: \n")
                require(lua_script_name)
                freeswitch.consoleLog("INFO", "END "..lua_script_name.." script: \n")
                isFinish = 1
            end
        )
    )  

end





local sql_query_users = string.format([[ 
    select id from web_users where "number-alias"='%s' 
    ]], req_destination_number
)

local sql_query_groupcall = string.format([[ 
    select id from web_callgroup where "number"='%s' 
    ]], req_destination_number
)

local sql_query_conference = string.format([[ 
    select id from web_conference where "number"='%s' 
    ]], req_destination_number
)

-- assert (
--     dbh:query(sql_query_users, 
--         function(u)  
--             freeswitch.consoleLog("INFO", "SATART call_local_number script: \n")
--             require("call_local_number")
--             freeswitch.consoleLog("INFO", "END call_local_number script: \n")
--             isFinish = 1
--         end
--     )
-- )  

if isFinish == 0 then
    direction(sql_query_users, "call_local_number")
end
if isFinish == 0 then
    direction(sql_query_groupcall, "call_local_groupcall")
end
if isFinish == 0 then
    direction(sql_query_conference, "call_local_conference")
end

if isFinish == 0 then
    freeswitch.consoleLog("WARNING", "Не найдено направление \n")
end

freeswitch.consoleLog("INFO", "Конец Определение направления в диалплане \n")