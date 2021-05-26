-- directory_xml.lua

freeswitch.consoleLog("notice","Формирование абонента для directory")
-- freeswitch.consoleLog("notice", "INFO from directory_xml.lua, provided params:\n" .. params:serialize() .. "\n")

local req_domain = params:getHeader("domain")
local req_key    = params:getHeader("key")
local req_user   = params:getHeader("user")
local req_group_name   = params:getHeader("group_name")
local req_action   = params:getHeader("action")

local db = require("db_odoo")
dbh = db.connect()

--end

freeswitch.consoleLog("notice","Конец Формирование абонента для GATEWAY")