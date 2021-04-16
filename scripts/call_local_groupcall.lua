-- Скрипт обрабатыват групповые вызовы

local records = require("records")

pathsep = '/'
freeswitch.consoleLog("notice","Вызов группы")

local req_destination_number   = session:getVariable("destination_number");
local req_domain   = session:getVariable("domain");
freeswitch.consoleLog("INFO", "req_destination_number: " .. req_destination_number .. "\n")
freeswitch.consoleLog("INFO", "req_domain: " .. req_domain .. "\n")

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
                                        FROM web_callgroup_line as cgl
                                        LEFT JOIN web_callgroup as cg ON cgl.callgroup_id=cg.id
                                        LEFT JOIN web_users as us ON us."number-alias"=cgl."number-alias"
                                        LEFT JOIN web_directory as dir ON dir.users_id=us.id
                                        LEFT JOIN web_domain as dom ON dom.id=us.domain_id
                                        WHERE dom.name = '%s' and cg.number='%s' and us.isdisable=false
                                    ]], req_domain, req_destination_number
)   
                                    
assert(dbh:query(sql_query, getgroup))

freeswitch.consoleLog("INFO", "users: " .. users .. "\n")

-- Если группа не найдена говорим что не существует, иначе вызываем абонентов группы
if (users=='') then
  freeswitch.consoleLog("INFO", "Группа с номером "..req_destination_number.." не найдена \n")
    session:answer()
    prompt ="ivr" ..pathsep .."ivr-you_have_dialed_an_invalid_extension.wav"
    session:streamFile(prompt)

else
  freeswitch.consoleLog("INFO", "Вызов абонентов группы по номерам: "..users.."\n")
  records.rec() --Запись разговоров, если включена у абонента
  records.rec_group() --Запись разговоров, если включена у группы
  session:execute("bridge", users);
end

session:hangup()
freeswitch.consoleLog("notice","Конец Вызов группы")