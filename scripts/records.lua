-- Модуль записи разговоров
local records = {}

freeswitch.consoleLog("notice","Модуль Записи разговора")

local req_destination_number   = session:getVariable("destination_number");
--local req_initial_callee_id_number   = session:getVariable("initial_callee_id_number");
local req_domain   = session:getVariable("domain");
local req_recordings_dir   = session:getVariable("recordings_dir");
local req_caller_id_number   = session:getVariable("caller_id_number");
local req_effective_caller_id_number   = session:getVariable("effective_caller_id_number");

--freeswitch.consoleLog("notice","req_initial_callee_id_number "..req_initial_callee_id_number)
freeswitch.consoleLog("notice","req_caller_id_number "..req_caller_id_number)
freeswitch.consoleLog("notice","req_destination_number "..req_destination_number)

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

--Номер звонящего
local caller_number = req_caller_id_number

function records.rec()
    -- Запись только после ответа
    session:setVariable("media_bug_answer_req","true");
    assert (
        dbh:query(sql_query_req_caller_id_number, function(u)
            caller_number = u.number -- Заменяем на читаемое имя
            if u.isrecord=='1' then
                freeswitch.consoleLog("INFO","Запись разговора вызывающего абонента "..req_caller_id_number.." включена")
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
                    freeswitch.consoleLog("INFO","Запись разговора вызываемого абонента "..req_destination_number.." включена")
                    record_file = req_recordings_dir.."/"..os.date("%Y-%m-%d__%H-%M-%S").."__"..req_destination_number.."__"..caller_number.."__in.wav"
                    session:execute("record_session", record_file);
                end
            end
        end
        )
    )
    
end



-- Поиск по номеру группы
local sql_query_group = string.format([[  
                                        SELECT
                                            gr.isrecord
                                        FROM web_callgroup as gr
                                        WHERE gr.number='%s' and gr.isrecord=true
                                        LIMIT 1
                                    ]], req_destination_number
)

--Функция записи группы
function records.rec_group()
    assert (
        dbh:query(
            sql_query_group, 
            function(u)
                session:setVariable("media_bug_answer_req","true");
                freeswitch.consoleLog("INFO","Запись разговора группы "..req_destination_number.." включена")
                record_file = req_recordings_dir.."/"..os.date("%Y-%m-%d__%H-%M-%S").."__"..req_destination_number.."__"..caller_number.."__group.wav"
                session:execute("record_session", record_file);
            end
        )
    )
end

return records