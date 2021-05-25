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

--if req_action == 'user_call' or req_action == 'sip_auth' then
  local dir_query = string.format([[SELECT *, 
                                          dir.number as number,
                                          dir.cidr as cidr,
                                          dir.regname as regname,
                                          us.name as name,
                                          dom.name as domain, 
                                          con.name as user_context, 
                                          us.name as username 
                                  FROM fs_directory as dir 
                                  LEFT JOIN fs_users as us ON us.id=dir.fs_users_id 
                                  LEFT JOIN fs_domain as dom ON dom.id=dir.domain_id 
                                  LEFT JOIN fs_context as con ON con.id=dir.context_id 
                                  WHERE dom.name = '%s' and dir.regname='%s' and dir.active=true
                                  LIMIT 1]], req_domain, req_user)
  
  assert (dbh:query(dir_query, function(u)
    XML_STRING =
              [[<?xml version="1.0" encoding="UTF-8" standalone="no"?>
              <document type="freeswitch/xml">
                <section name="directory">
                  <domain name="]] .. u.domain .. [[">
                          <user id="]] .. u.regname .. [[" cidr="]]
                        .. u.cidr .. [[" number-alias="]] .. u.number .. [[">
                      <params>
                        <param name="password" value="]] .. u.password .. [["/>
                        <param name="dial-string" value="{sip_secure_media=${regex(${sofia_contact(${dialed_user}@${dialed_domain})}|transport=tls)},presence_id=${dialed_user}@${dialed_domain}}${sofia_contact(${dialed_user}@${dialed_domain})}"/>
                        <param name="jsonrpc-allowed-methods" value="verto"/>
                        <param name="jsonrpc-allowed-event-channels" value="demo,conference"/>
                      </params>
                      <variables>
                        <variable name="user_context" value="]] .. u.user_context .. [["/>
                  <variable name="effective_caller_id_name" value="]] .. u.name .. [["/>
                  <variable name="effective_caller_id_number" value="]] .. u.number .. [["/>
                  <variable name="outbound_caller_id_name" value="]] .. u.name .. [["/>
                  <variable name="outbound_caller_id_number" value="]] .. u.number .. [["/>
                      
                      </variables>
                      
                    </user>
                  </domain>
                </section>
              </document>]]
        freeswitch.consoleLog("notice","XML directory для абонента "..req_user.." - "..u.name.." сформирован")
  end))
--end

freeswitch.consoleLog("notice","Конец Формирование абонента для directory")