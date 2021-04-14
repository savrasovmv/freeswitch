--Модуль подключения к БД
local db = {}

local pg_host   = session:getVariable("pg_host");
local pg_db   = session:getVariable("pg_db");
local pg_user   = session:getVariable("pg_user");
local pg_password   = session:getVariable("pg_password");


local dbh = freeswitch.Dbh("odbc://freeswitch:freeswitch:freeswitch")

function db.connect()
    if dbh:connected() == false then
        freeswitch.consoleLog("WARNING", "lua cannot connect to database \n")
        return
    else
        freeswitch.consoleLog("INFO", "CONNECT TO PG \n")
        return dbh
    end
end

return db