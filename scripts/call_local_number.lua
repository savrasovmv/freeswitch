-- test3.lua
-- Answer call, play a prompt, hang up
-- Set the path separator
pathsep = '/'
-- Windows users do this instead:
-- pathsep = ''
-- Answer the call
freeswitch.consoleLog("WARNING","Вызов группы")
--session:answer()
--freeswitch.consoleLog("WARNING","Already answeredn")
-- Create a string with path and filename of a sound file
--prompt ="ivr" ..pathsep .."ivr-welcome_to_freeswitch.wav"
-- Play the prompt
--freeswitch.consoleLog("WARNING","About to play '" .. prompt .."'n")
--freeswitch.consoleLog("WARNING",session:serialize())
--session:streamFile(prompt)
--session:execute("playback", "local_stream://moh");
--session:execute("bridge", "user/1000@192.168.1.8");

local req_user   = session:getVariable("destination_number");
local req_domain   = session:getVariable("domain");
freeswitch.consoleLog("WARNING", "req_user: " .. req_user .. "\n")
freeswitch.consoleLog("WARNING", "req_domain: " .. req_domain .. "\n")


local dbh = freeswitch.Dbh("odbc://freeswitch:freeswitch:freeswitch")
if dbh:connected() == false then
  freeswitch.consoleLog("WARNING", "lua cannot connect to database \n")
  return
else
  freeswitch.consoleLog("WARNING", "++++++++ CONNECT TO PG \n")
end
local users = ''
function getgroup(row)
    freeswitch.consoleLog("WARNING", "1111  getgroup \n")
    
    for col, val in pairs(row) do
      freeswitch.consoleLog("WARNING", "val:" .. val .. "\n")
      if (users~='') then
        users =  users ..","
      end
      users =  users .. "user/" ..val .. "@" .. req_domain
      row[col] = val
    end
   
  
end



-- local sql_query = string.format([[  SELECT
--                                         dir.regname 
--                                     FROM web_directory as dir 
--                                     LEFT JOIN web_users as us on us.id=dir.users_id 
--                                     LEFT JOIN web_domain as dom ON dom.id=us.domain_id 
--                                     LEFT JOIN web_context as con ON con.id=us.context_id 
--                                     WHERE dom.name = '%s' and us."number-alias"='%s'
--                                     ]], req_domain, req_user)

local sql_query = string.format([[  SELECT
                                            dir.regname
                                        FROM web_directory as dir 
                                        LEFT JOIN web_users as us on us.id=dir.users_id 
                                        LEFT JOIN web_domain as dom ON dom.id=us.domain_id 
                                        LEFT JOIN web_context as con ON con.id=us.context_id 
                                        WHERE dom.name = '%s' and us."number-alias"='%s' and us.isdisable=false
                                    ]], req_domain, req_user)                                    
assert(
  dbh:query(sql_query, getgroup),

  freeswitch.consoleLog("WARNING", "Запрос " .. sql_query .. "\n")
)
freeswitch.consoleLog("WARNING", "users: " .. users .. "\n")
--local row = getgroup()
if (users=='') then
    freeswitch.consoleLog("WARNING", "users==NULLL \n")
    session:answer()
    prompt ="ivr" ..pathsep .."ivr-you_have_dialed_an_invalid_extension.wav"
    session:streamFile(prompt)

else
    freeswitch.consoleLog("WARNING", "users==not NULLL \n")
    session:setVariable("effective_caller_id_name", "Группа");
    session:execute("bridge", users);
end
--session:execute("bridge", "user/1019@192.168.1.8,user/user2@192.168.1.8");
--freeswitch.consoleLog("WARNING","After playing '" .. prompt .."'n")
-- Hangup
session:hangup()
freeswitch.consoleLog("WARNING","Afterhangupn")