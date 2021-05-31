-- directory_xml.lua

freeswitch.consoleLog("notice","Формирование GATEWAY")
freeswitch.consoleLog("notice", "[xml_handler] Key Value: " .. XML_REQUEST["key_value"] .. "\n");
freeswitch.consoleLog("notice", "[section] Key Value: " .. XML_REQUEST["section"] .. "\n");
freeswitch.consoleLog("notice", "[tag_name] Key Value: " .. XML_REQUEST["tag_name"] .. "\n");
freeswitch.consoleLog("notice", "[key_name] Key Value: " .. XML_REQUEST["key_name"] .. "\n");
-- freeswitch.consoleLog("notice", "INFO from directory_xml.lua, provided params:\n" .. params:serialize() .. "\n")

-- local req_domain = params:getHeader("domain")
-- local req_key    = params:getHeader("key")
-- local req_user   = params:getHeader("user")
-- local req_group_name   = params:getHeader("group_name")
-- local req_action   = params:getHeader("action")
local key_value   = XML_REQUEST["key_value"]

local global_codec_prefs   = freeswitch.getGlobalVariable("global_codec_prefs");
local external_sip_port   = freeswitch.getGlobalVariable("external_sip_port");
local local_ip_v4   = freeswitch.getGlobalVariable("local_ip_v4");
local internal_sip_port   = freeswitch.getGlobalVariable("internal_sip_port");
local kerio_host   = freeswitch.getGlobalVariable("kerio_host");
-- local db = require("db_odoo")
-- dbh = db.connect()

--end

if (key_value=='sofia.conf') then
    local db = require("db_odoo")
    dbh = db.connect()
    local dir_query = string.format([[SELECT * FROM fs_directory WHERE active=True]])
    -- assert (dbh:query(dir_query, function(u)
    --     table.insert(xml, [[

    --                                             <gateway name="]] .. u.regname .. [[">
    --                                                 <param name="username" value="]] .. u.regname .. [["/>
    --                                                 <param name="password" value="]] .. u.password .. [["/>
    --                                                 <param name="proxy" value="192.168.1.11"/>
    --                                                 <param name="register" value="true"/>
    --                                             </gateway>


    --         ]]);
    -- end))

    local xml = {}
    table.insert(xml, [[<?xml version="1.0" encoding="UTF-8" standalone="no"?>]]);
    table.insert(xml, [[<document type="freeswitch/xml">]]);
    table.insert(xml, [[          	<section name="configuration">]]);
    table.insert(xml, [[          		<configuration name="sofia.conf" description="sofia Endpoint">]]);
    table.insert(xml, [[          			<global_settings>]]);
    table.insert(xml, [[          				<param name="log-level" value="0"/>]]);
    table.insert(xml, [[          				<param name="auto-restart" value="false"/>]]);
    table.insert(xml, [[          				<param name="debug-presence" value="0"/>]]);
    table.insert(xml, [[          			</global_settings>]]);
    table.insert(xml, [[          			 <profiles>]]);
    table.insert(xml, [[          			    <profile name="internal">
                                                    <settings>
                                                        <!-- Заменить на true для продакшена!! -->
                                                        <param name="auth-calls" value="true"/>
                                                        <param name="apply-nat-acl" value="nat.auto"/>

                                                        <param name="debug" value="0"/>
                                                        <!-- Включить в лог sip пакеты -->
                                                        <!-- <param name="sip-trace" value="yes"/> -->
                                                        <param name="sip-trace" value="no"/>

                                                        <param name="dialplan" value="XML"/>
                                                        <param name="context" value="private"/>
                                                        <param name="codec-prefs" value="]] .. global_codec_prefs .. [["/>

                                                        <param name="rtp-ip" value="]] .. local_ip_v4 .. [["/>
                                                        <param name="sip-ip" value="]] .. local_ip_v4 .. [["/>
                                                        <param name="ext-rtp-ip" value="auto-nat"/>
                                                        <param name="ext-sip-ip" value="auto-nat"/>internal_sip_port
                                                        <param name="sip-port" value="]] .. internal_sip_port .. [["/>

                                                        <param name="tls-cert-dir" value="/usr/local/freeswitch/certs"/>
                                                        <param name="wss-binding" value="]] .. local_ip_v4 .. [[:7443"/>
                                                        
                                                       
                                                    </settings>
    
    
                                  			    </profile>]]);
    table.insert(xml, [[          			   
                                <profile name="external">
                                    <gateways>]]);
    assert (dbh:query(dir_query, function(u)
        table.insert(xml, [[

                                                <gateway name="]] .. u.regname .. [[">
                                                    <param name="username" value="]] .. u.regname .. [["/>
                                                    <param name="password" value="]] .. u.password .. [["/>
                                                    <param name="proxy" value="]] .. kerio_host .. [["/>
                                                    <param name="register" value="true"/>
                                                </gateway>


            ]]);
    end))
    table.insert(xml, [[          	</gateways>]]);
    table.insert(xml, [[            <!-- Тест  -->
                                    <!-- <aliases>
                                        <alias name="default"/>
                                    </aliases>
                                    <domains>
                                        <domain name="all" alias="false" parse="true"/>
                                    </domains> -->
    
                                    <settings>
                                        <param name="auth-calls" value="false"/>
    
                                        <param name="debug" value="0"/>
    
                                        <param name="dialplan" value="XML"/>
                                        <param name="context" value="public"/>
                                        <param name="codec-prefs" value="]] .. global_codec_prefs .. [["/>
    
                                        <param name="rtp-ip" value="]] .. local_ip_v4 .. [[""/>
                                        <param name="sip-ip" value="]] .. local_ip_v4 .. [[""/>
                                        <param name="ext-rtp-ip" value="auto-nat"/>
                                        <param name="ext-sip-ip" value="auto-nat"/>
                                        <param name="sip-port" value="]] .. external_sip_port .. [["/>
                                        
                                    </settings>
                                    </profile>

    ]]);
    table.insert(xml, [[          			</profiles>]]);
    table.insert(xml, [[             </configuration>]]);
    table.insert(xml, [[         </section>]]);
    table.insert(xml, [[ </document>]]);
    XML_STRING = table.concat(xml, "\n")

    -- <Z-PRE-PROCESS cmd="include" data="external/*.xml"/>
    --                                     <Z-PRE-PROCESS cmd="exec" data="gateway.lua"/>
    --                                     <gateway name="110rc11">
    --                                         <param name="username" value="110rc"/>
    --                                         <param name="password" value="Gfhjkm12@"/>
    --                                         <param name="proxy" value="192.168.1.11"/>
    --                                         <param name="register" value="true"/>
    --                                     </gateway>
    --                                     <gateway name="110rc">
    --                                         <param name="username" value="110rc"/>
    --                                         <param name="password" value="Gfhjkm12@"/>
    --                                         <param name="proxy" value="192.168.1.11"/>
    --                                         <param name="register" value="true"/>
    --                                     </gateway>
    --                                     <gateway name="110rc222">
    --                                         <param name="username" value="110rc"/>
    --                                         <param name="password" value="Gfhjkm12@"/>
    --                                         <param name="proxy" value="192.168.1.11"/>
    --                                         <param name="register" value="true"/>
    --                                     </gateway>




    -- XML_STRING =
    --             [[
    --             <?xml version="1.0"?>
    --             <document type="freeswitch/xml">
    --                 <configuration name="sofia.conf" description="sofia Endpoint">
    --                     <global_settings>
    --                         <param name="log-level" value="0"/>
    --                         <param name="tracelevel" value="DEBUG"/>
    --                         <param name = "auto-restart" value = "false" />
    --                     </global_settings>

    --                     <profiles>
    --                         <profile name="internal">
    --                             <!-- Тест  -->
    --                             <aliases>
    --                                 <alias name="default"/>
    --                             </aliases>
    --                             <domains>
    --                                 <domain name="all" alias="false" parse="true"/>
    --                             </domains>
                                
    --                             <settings>
    --                                 <!-- Заменить на true для продакшена!! -->
    --                                 <param name="auth-calls" value="true"/>
    --                                 <param name="apply-nat-acl" value="nat.auto"/>
                                
    --                                 <param name="debug" value="0"/>
    --                                 <!-- Включить в лог sip пакеты -->
    --                                 <!-- <param name="sip-trace" value="yes"/> -->
    --                                 <param name="sip-trace" value="no"/>
                                
    --                                 <param name="dialplan" value="XML"/>
    --                                 <param name="context" value="private"/>
    --                                 <param name="codec-prefs" value="$${global_codec_prefs}"/>
                                
    --                                 <param name="rtp-ip" value="$${local_ip_v4}"/>
    --                                 <param name="sip-ip" value="$${local_ip_v4}"/>
    --                                 <param name="ext-rtp-ip" value="auto-nat"/>
    --                                 <param name="ext-sip-ip" value="auto-nat"/>
    --                                 <param name="sip-port" value="$${internal_sip_port}"/>
    --                                 <!-- PG connect -->
    --                                 <param name="odbc-dsn" value="pgsql://hostaddr=$${pg_host} dbname=$${pg_db}  user=$${pg_user} password=$${pg_password}"/>
    --                             </settings>
    --                         </profile>


    --                         <profile name="external">
    --                             <gateways>
    --                                 <Z-PRE-PROCESS cmd="include" data="external/*.xml"/>
    --                                 <Z-PRE-PROCESS cmd="exec" data="gateway.lua"/>
    --                                 <gateway name="110rc11">
    --                                     <param name="username" value="110rc"/>
    --                                     <param name="password" value="Gfhjkm12@"/>
    --                                     <param name="proxy" value="192.168.1.11"/>
    --                                     <param name="register" value="true"/>
    --                                 </gateway>
    --                             </gateways>

    --                             <!-- Тест  -->
    --                             <!-- <aliases>
    --                                 <alias name="default"/>
    --                             </aliases>
    --                             <domains>
    --                                 <domain name="all" alias="false" parse="true"/>
    --                             </domains> -->

    --                             <settings>
    --                                 <param name="auth-calls" value="false"/>

    --                                 <param name="debug" value="0"/>

    --                                 <param name="dialplan" value="XML"/>
    --                                 <param name="context" value="public"/>
    --                                 <param name="codec-prefs" value="$${global_codec_prefs}"/>

    --                                 <param name="rtp-ip" value="$${local_ip_v4}"/>
    --                                 <param name="sip-ip" value="$${local_ip_v4}"/>
    --                                 <param name="ext-rtp-ip" value="auto-nat"/>
    --                                 <param name="ext-sip-ip" value="auto-nat"/>
    --                                 <param name="sip-port" value="$${external_sip_port}"/>
                                    
    --                             </settings>
    --                             </profile>

                            
    --                     </profiles>
    --                 </configuration>
    --             </document>
    --             ]]
    freeswitch.consoleLog("notice", "Debug from GATEWAY, generated XML:\n" .. XML_STRING .. "\n")
end
freeswitch.consoleLog("notice","Конец Формирование абонента для GATEWAY")
