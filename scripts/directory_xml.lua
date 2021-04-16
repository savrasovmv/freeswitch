-- directory_xml.lua

freeswitch.consoleLog("notice","Формирование абонента для directory")
-- freeswitch.consoleLog("notice", "INFO from directory_xml.lua, provided params:\n" .. params:serialize() .. "\n")

local req_domain = params:getHeader("domain")
local req_key    = params:getHeader("key")
local req_user   = params:getHeader("user")
local req_group_name   = params:getHeader("group_name")
local req_action   = params:getHeader("action")

local db = require("db")
dbh = db.connect()

--if req_action == 'user_call' or req_action == 'sip_auth' then
  local dir_query = string.format([[SELECT *, 
                                          us.name as name,
                                          dom.name as domain, 
                                          con.name as user_context, 
                                          us.name as username 
                                  FROM web_directory as dir 
                                  LEFT JOIN web_users as us ON us.id=dir.users_id 
                                  LEFT JOIN web_domain as dom ON dom.id=us.domain_id 
                                  LEFT JOIN web_context as con ON con.id=us.context_id 
                                  WHERE dom.name = '%s' and dir.regname='%s' and us.isdisable=false
                                  LIMIT 1]], req_domain, req_user)
  
  assert (dbh:query(dir_query, function(u)
    XML_STRING =
              [[<?xml version="1.0" encoding="UTF-8" standalone="no"?>
              <document type="freeswitch/xml">
                <section name="directory">
                  <domain name="]] .. u.domain .. [[">
                          <user id="]] .. u.regname .. [[" mailbox="]] .. u.mailbox .. [[" cidr="]]
                        .. u.cidr .. [[" number-alias="]] .. u["number-alias"] .. [[">
                      <params>
                        <param name="password" value="]] .. u.password .. [["/>
                        <param name="dial-string" value="{sip_secure_media=${regex(${sofia_contact(${dialed_user}@${dialed_domain})}|transport=tls)},presence_id=${dialed_user}@${dialed_domain}}${sofia_contact(${dialed_user}@${dialed_domain})}"/>
                        <param name="jsonrpc-allowed-methods" value="verto"/>
                        <param name="jsonrpc-allowed-event-channels" value="demo,conference"/>
                      </params>
                      <variables>
                  <variable name="toll_allow" value="]] .. u.toll_allow .. [["/>
                        <variable name="user_context" value="]] .. u.user_context .. [["/>
                  <variable name="default_gateway" value="]] .. u.default_gateway .. [["/>
                  <variable name="effective_caller_id_name" value="]] .. u.username .. [["/>
                  <variable name="effective_caller_id_number" value="]] .. u["number-alias"] .. [["/>
                  <variable name="outbound_caller_id_name" value="]] .. u.outbound_caller_id_name .. [["/>
                  <variable name="outbound_caller_id_number" value="]] .. u.outbound_caller_id_number .. [["/>
                        <variable name="callgroup" value="]] .. u.username .. [["/>
                      
                      </variables>
                    </user>
                  </domain>
                </section>
              </document>]]
        freeswitch.consoleLog("INFO","XML directory для абонента "..req_user.." - "..u.username.." сформирован")
  end))
--end

freeswitch.consoleLog("notice","Конец Формирование абонента для directory")