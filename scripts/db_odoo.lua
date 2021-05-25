--Модуль подключения к БД
local db = {}

-- local pg_host   = session:getVariable("pg_host");
-- local pg_db   = session:getVariable("pg_db");
-- local pg_user   = session:getVariable("pg_user");
-- local pg_password   = session:getVariable("pg_password");

local pg_host   = freeswitch.getGlobalVariable("pg_host");
local pg_db   = freeswitch.getGlobalVariable("pg_db");
local pg_user   = freeswitch.getGlobalVariable("pg_user");
local pg_password   = freeswitch.getGlobalVariable("pg_password");

local dbh = freeswitch.Dbh("odbc://odoo:freeswitch:password")

function db.connect()
    if dbh:connected() == false then
        freeswitch.consoleLog("WARNING", "lua cannot connect to database ODOO \n")
        return
    else
        freeswitch.consoleLog("INFO", "CONNECT TO PG ODOO \n")
        return dbh
    end
end

return db