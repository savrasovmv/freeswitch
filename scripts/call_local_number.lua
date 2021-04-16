-- Звонки на внутренние номера

pathsep = '/'
freeswitch.consoleLog("notice","Вызов внутреннего номера")

local req_destination_number   = session:getVariable("destination_number");
local req_domain   = session:getVariable("domain");
local req_recordings_dir   = session:getVariable("recordings_dir");
local req_caller_id_number   = session:getVariable("caller_id_number");
freeswitch.consoleLog("INFO", "req_destination_number: " .. req_destination_number .. "\n")
freeswitch.consoleLog("WARNINFOING", "req_domain: " .. req_domain .. "\n")

local records = require("records")

local db = require("db")
dbh = db.connect()

local users = ''

--Функция формирует строку для bridge вида user/1019rc@192.168.1.8,user/1019tel@192.168.1.8
function getgroup(row)
    for col, val in pairs(row) do
      if (users~='') then
        users =  users ..","
      end
      users =  users .. "user/" ..val .. "@" .. req_domain
      row[col] = val
    end
end


local sql_query = string.format([[  SELECT
                                            dir.regname
                                        FROM web_directory as dir 
                                        LEFT JOIN web_users as us on us.id=dir.users_id 
                                        LEFT JOIN web_domain as dom ON dom.id=us.domain_id 
                                        LEFT JOIN web_context as con ON con.id=us.context_id 
                                        WHERE dom.name = '%s' and us."number-alias"='%s' and us.isdisable=false
                                    ]], req_domain, req_destination_number
)                                    

assert(dbh:query(sql_query, getgroup))

freeswitch.consoleLog("INFO", "users: " .. users .. "\n")

-- Если абонент не найден говорим что не существует, иначе вызываем абонента
if (users=='') then
    freeswitch.consoleLog("INFO", "Абонент с номером "..req_destination_number.." не найден\n")
    session:answer()
    prompt ="ivr" ..pathsep .."ivr-you_have_dialed_an_invalid_extension.wav"
    session:streamFile(prompt)
else
    freeswitch.consoleLog("INFO", "Вызов абонента по номерам: "..users.."\n")
    
    records.rec() --Запись разговоров, если включена у абонента
    session:execute("bridge", users);
    
end
-- Hangup
session:hangup()
freeswitch.consoleLog("notice","Конец Вызов внутреннего номера")
