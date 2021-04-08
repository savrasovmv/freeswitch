-- directory_xml.lua
-- freeswitch.consoleLog("notice", "Debug from directory_xml.lua, provided params:\n" .. params:serialize() .. "\n")
 
local req_domain = params:getHeader("domain")
local req_key    = params:getHeader("key")
local req_user   = params:getHeader("user")
local req_group_name   = params:getHeader("group_name")
local req_action   = params:getHeader("action")

freeswitch.consoleLog("info",params:serialize())
--assert (req_domain and req_key and req_user,
--  "This example script only supports generating directory xml for a single user !\n")
 
local dbh = freeswitch.Dbh("odbc://freeswitch:freeswitch:freeswitch")
if dbh:connected() == false then
  freeswitch.consoleLog("notice", "directory_xml.lua cannot connect to database \n")
  return
else
  freeswitch.consoleLog("notice", "++++++++ CONNECT TO PG \n")
end

-- function getgroup()
--   local rows = {}
--   local dir_query = string.format("select d.userid from directory as d left join groups as g on g.id=d.group_id where g.domain = '%s' and g.name= '%s'", req_domain, req_group_name)
--   assert (dbh:query(dir_query, function(data)
--     local row = {}
--     for col, val in pairs(data) do
--       row[col] = val
--     end
--     table.insert(rows, row)
--   end))
--   return rows
  
-- end


-- if req_action == 'group_call' then
--   local rows = getgroup()
--   local str = ''
--   --freeswitch.consoleLog("notice", "++++++++//////////+++++++\n" .. rows .. "\n" )
--   for col, val in pairs(rows) do
--     for col2, val2 in pairs(val) do
--       freeswitch.consoleLog("notice", "++++++++//////////+++++++\n" .. val2 .. "\n" )
--       str = str .. '<user id="'.. val2 ..'" type="pointer"/>'
--     end
--   end

--   freeswitch.consoleLog("notice", "AAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" .. str .. "\n")
--   XML_STRING = [[<?xml version="1.0" encoding="UTF-8" standalone="no"?>
--     <document type="freeswitch/xml">
--     <section name="directory">
--       <domain name="192.168.1.8">
--         <groups>
--           <group name="1100">
--             <users>]]
--               .. str ..
--             [[</users>
--       </group>
--     </groups>
--     </domain>
--     </section>
--     </document>]]
--     freeswitch.consoleLog("notice", "Debug from directory_xml.lua, generated XML:\n" .. XML_STRING .. "\n")
-- end

   

if req_action == 'user_call' or req_action == 'sip_auth' then
  local dir_query = string.format([[SELECT *, 
                                          dom.name as domain, 
                                          con.name as user_context, 
                                          us.name as callgroup 
                                  FROM web_directory as dir 
                                  LEFT JOIN web_users as us ON us.id=dir.users_id 
                                  LEFT JOIN web_domain as dom ON dom.id=us.domain_id 
                                  LEFT JOIN web_context as con ON con.id=us.context_id 
                                  where dom.name = '%s' and dir.regname='%s' limit 1]], req_domain, req_user)
  freeswitch.consoleLog("notice", "++++++++ dir_query \n" .. dir_query .. "\n")
  
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
      <variable name="effective_caller_id_name" value="]] .. u.effective_caller_id_name .. [["/>
      <variable name="effective_caller_id_number" value="]] .. u.effective_caller_id_number .. [["/>
      <variable name="outbound_caller_id_name" value="]] .. u.outbound_caller_id_name .. [["/>
      <variable name="outbound_caller_id_number" value="]] .. u.outbound_caller_id_number .. [["/>
            <variable name="callgroup" value="]] .. u.callgroup .. [["/>
          
          </variables>
        </user>
      </domain>
    </section>
  </document>]]
  
    -- закомментируйте для продакшн:
    freeswitch.consoleLog("notice", "Debug from directory_xml.lua, generated XML:\n" .. XML_STRING .. "\n")
  end))
end