-- Модуль записи разговоров
local records = {}

freeswitch.consoleLog("notice","Модуль Записи разговора")

local req_destination_number   = session:getVariable("destination_number");
local req_initial_callee_id_number   = session:getVariable("initial_callee_id_number");
local req_domain   = session:getVariable("domain");
local req_recordings_dir   = session:getVariable("recordings_dir");
local req_caller_id_number   = session:getVariable("caller_id_number");
local req_effective_caller_id_number   = session:getVariable("effective_caller_id_number");

freeswitch.consoleLog("notice","req_initial_callee_id_number "..req_initial_callee_id_number)
freeswitch.consoleLog("notice","req_caller_id_number "..req_caller_id_number)

local db = require("db")
dbh = db.connect()

-- Поиск набранного номера
local sql_query_destination_number = string.format([[  
                                        SELECT
                                            us.isrecord
                                        FROM web_users as us 
                                        LEFT JOIN web_domain as dom ON dom.id=us.domain_id 
                                        WHERE dom.name = '%s' and us."number-alias"='%s' and us.isdisable=false
                                        LIMIT 1
                                    ]], req_domain, req_destination_number
) 

-- Поиск по номеру звонящего
local sql_query_req_caller_id_number = string.format([[  
                                        SELECT
                                            us.isrecord,
                                            us."number-alias" as number
                                        FROM web_users as us 
                                        LEFT JOIN web_domain as dom ON dom.id=us.domain_id 
                                        LEFT JOIN web_directory as dir ON dir.users_id=us.id
                                        WHERE dom.name = '%s' and dir.regname='%s' and us.isdisable=false
                                        LIMIT 1
                                    ]], req_domain, req_caller_id_number
)                                 

function records.rec()
    -- Запись только после ответа
    session:setVariable("media_bug_answer_req","true");
    local caller_number = req_caller_id_number
    assert (
        dbh:query(sql_query_req_caller_id_number, function(u)
            caller_number = u.number -- Заменяем на читаемое имя
            if u.isrecord=='1' then
                freeswitch.consoleLog("DEBUG","Запись разговора вызывающего абонента "..req_caller_id_number.." включена")
                record_file = req_recordings_dir.."/"..os.date("%Y-%m-%d__%H-%M-%S").."__"..caller_number.."__"..req_destination_number.."__out.wav"
                session:execute("record_session", record_file);
            end
        end
        )
    )
    assert (
        dbh:query(sql_query_destination_number, function(u)
            if u.isrecord=='1' then
                if session:ready() then
                freeswitch.consoleLog("DEBUG","Запись разговора вызываемого абонента "..req_destination_number.." включена")
                record_file = req_recordings_dir.."/"..os.date("%Y-%m-%d__%H-%M-%S").."__"..req_destination_number.."__"..caller_number.."__in.wav"
                session:execute("record_session", record_file);
                end
            end
        end
        )
    )
    
end

-- Функция записи конференции
function records.rec_conf()
    -- Запись только после ответа
    session:setVariable("media_bug_answer_req","true");
    record_file = req_recordings_dir.."/"..os.date("%Y-%m-%d__%H-%M-%S").."__"..req_destination_number.."__"..req_effective_caller_id_number.."__conference.wav"
    session:execute("record_session", record_file);
end

return records