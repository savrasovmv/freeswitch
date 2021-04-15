-- conference.lua

freeswitch.consoleLog("notice","Вызов конференции")

local records = require("records")
pathsep = '/'


local req_number   = session:getVariable("destination_number");
local req_domain   = session:getVariable("domain");
local req_recordings_dir   = session:getVariable("recordings_dir");
local req_caller_id_number   = session:getVariable("caller_id_number");


freeswitch.consoleLog("DEBUG", "req_number: " .. req_number .. "\n")
freeswitch.consoleLog("DEBUG", "req_domain: " .. req_domain .. "\n")
freeswitch.consoleLog("DEBUG", "req_caller_id_number: " .. req_caller_id_number .. "\n")

local db = require("db")
dbh = db.connect()

local sql_query = string.format([[  SELECT
                                            *
                                        FROM web_conference 
                                        WHERE number='%s'
                                        LIMIT 1
                                    ]], req_number) 


                                    function on_dtmf(session, type, obj, arg)
                                        
                                           
                                           return true;
                                        end


local error_number=1
assert (
    dbh:query(sql_query, 
        function(u)  

            local password = ''
            local record_file = ''

            if (u.issecret=='1' and u.password~='')  then
                password = "+"..u.password
                --Установить кол-во попыток ввода пароля
                session:setVariable("pin-retries", "3");
            end

            
            
            session:answer()
            if (u.isrecord=='1')  then
                records.rec_conf() --Запись конференции
            end
            -- if (u.isrecord=='1')  then
            --     record_file = req_recordings_dir.."/"..req_caller_id_number.."_to_"..req_number.."_"..os.date("%Y-%m-%d-%H-%M-%S")..".wav"
            --     freeswitch.consoleLog("DEBUG","record_file: "..record_file)
            -- end

            -- if (record_file~='') then
            --    session:execute("record_session", record_file);
            --    --freeswitch.setVariable("auto-record", record_file);
            --    --session:recordFile(record_file, 3, 500, 3);
            -- end

            session:execute("conference", req_number.."-"..req_domain.."@"..u.profile..password);
            session:hangup()
            error_number=0

        end
    )
)  

    --Обработка ошибок
if error_number==1 then
    freeswitch.consoleLog("DEBUG","Конференция не существует")
    session:answer()
    prompt ="ivr" ..pathsep .."ivr-you_have_dialed_an_invalid_extension.wav"
    session:streamFile(prompt)
    session:hangup()
                       
end

freeswitch.consoleLog("notice","Конец обработки конференции") 

