-- conference.lua

-- Answer call, play a prompt, hang up
-- Set the path separator
pathsep = '/'
-- Windows users do this instead:
-- pathsep = ''
-- Answer the call
freeswitch.consoleLog("WARNING","Вызов конференции")


local lua_scripts_dir   = session:getVariable("lua_scripts_dir");
local req_number   = session:getVariable("destination_number");
local req_domain   = session:getVariable("domain");
local req_recordings_dir   = session:getVariable("recordings_dir");
local req_caller_id_number   = session:getVariable("caller_id_number");

freeswitch.consoleLog("WARNING", "req_number: " .. req_number .. "\n")
freeswitch.consoleLog("WARNING", "req_domain: " .. req_domain .. "\n")
freeswitch.consoleLog("WARNING", "req_recordings_dir: " .. req_recordings_dir .. "\n")
freeswitch.consoleLog("WARNING", "req_caller_id_number: " .. req_caller_id_number .. "\n")

--package.path = package.path..";./?.lua"
local db = require(lua_scripts_dir.."/db")
dbh = db.connect()

-- local dbh = freeswitch.Dbh("odbc://freeswitch:freeswitch:freeswitch")
-- if dbh:connected() == false then
--   freeswitch.consoleLog("WARNING", "lua cannot connect to database \n")
--   return
-- else
--   freeswitch.consoleLog("WARNING", "++++++++ CONNECT TO PG \n")
-- end

local sql_query = string.format([[  SELECT
                                            *
                                        FROM web_conference 
                                        WHERE number='%s'
                                        LIMIT 1
                                    ]], req_number) 

local error_number=1
assert (
    dbh:query(sql_query, 
        function(u)  
            local password = ''
            local record_file = ''
            freeswitch.consoleLog("WARNING","issecret: "..u.issecret)
            freeswitch.consoleLog("WARNING","password: "..u.password)
            if (u.issecret=='1' and u.password~='')  then
                password = "+"..u.password
                freeswitch.consoleLog("WARNING","conference password "..password)
                --Установить кол-во попыток ввода пароля
                session:setVariable("pin-retries", "3");
            end
            if (u.isrecord=='1')  then
                record_file = req_recordings_dir.."/"..req_caller_id_number.."_to_"..req_number.."_"..os.date("%Y-%m-%d-%H-%M-%S")..".wav"
                freeswitch.consoleLog("WARNING","record_file: "..record_file)
            end
            
            session:answer()
            if (record_file~='') then
               session:execute("record_session", record_file);
            end
            session:execute("conference", req_number.."-"..req_domain.."@"..u.profile..password);
            session:hangup()
            error_number=0
        end
    )


)  
    --Обработка ошибок
if error_number==1 then
    freeswitch.consoleLog("WARNING","Конференции не существует")
    session:answer()
    prompt ="ivr" ..pathsep .."ivr-you_have_dialed_an_invalid_extension.wav"
    session:streamFile(prompt)
    session:hangup()
                       
end
freeswitch.consoleLog("WARNING","Конец обработки конференции") 

