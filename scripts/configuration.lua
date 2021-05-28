freeswitch.consoleLog("notice","Скрипт configuration.lua")
freeswitch.consoleLog("notice", "[xml_handler] Key Value: " .. XML_REQUEST["key_value"] .. "\n");
freeswitch.consoleLog("notice", "[section] Key Value: " .. XML_REQUEST["section"] .. "\n");
freeswitch.consoleLog("notice", "[tag_name] Key Value: " .. XML_REQUEST["tag_name"] .. "\n");
freeswitch.consoleLog("notice", "[key_name] Key Value: " .. XML_REQUEST["key_name"] .. "\n");

local key_value   = XML_REQUEST["key_value"]
local section   = XML_REQUEST["section"]

if (key_value=='sofia.conf' and section=='configuration') then
    require("sofia_config")
end

if (section=='directory') then
    require("directory_xml")
end