-- This script contains common functions that are used in many script.
-- How to use: common_functions:IsFileExist(path to file)
--------------------------------------------------------------------------------
local common_functions = {}
-- COMMON FUNCTIONS FOR FILE AND FOLDER
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function common_functions:DeleteLogsFileAndPolicyTable(DeleteLogsFlags)
  common_functions:DeletePolicyTable()
  DeleteLogsFlags = DeleteLogsFlags or true
  if DeleteLogsFlags then
    --Delete app_info.dat and log files
    self:DeleteLogsFiles()
  end
end

function common_functions:DeletePolicyTable()
  common_functions:CheckSdlPath()
  local policy_file = config.pathToSDL .. common_functions:GetValueFromIniFile("AppStorageFolder") .. "/policy.sqlite"
  if common_functions:IsFileExist(policy_file) then
    os.execute("rm -f " .. policy_file)
  end
  policy_file = config.pathToSDL .. "policy.sqlite"
  if common_functions:IsFileExist(policy_file) then
    os.execute("rm -f " .. policy_file)
  end
end

function common_functions:DeleteLogsFiles()
  common_functions:CheckSdlPath()
  if self:IsFileExist(config.pathToSDL .. "app_info.dat") then
    os.execute("rm -f " .. config.pathToSDL .. "app_info.dat")
  end

  os.execute("rm -f " .. config.pathToSDL .. "*.log") 
end

-- Check file existence
-- @param file_name:
--------------------------------------------------------------------------------
function common_functions:IsFileExist(file_name)
  local f=io.open(file_name,"r")

  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

-- Check directory existence
function common_functions:IsDirectoryExist(DirectoryPath)
  local returnValue
  local Command = assert( io.popen( "[ -d " .. tostring(DirectoryPath) .. " ] && echo \"Exist\" || echo \"NotExist\"" , 'r'))
  local CommandResult = tostring(Command:read( '*l' ))
  if CommandResult == "NotExist" then
    returnValue = false
  elseif CommandResult == "Exist" then
    returnValue = true
  else
    common_functions:userPrint(31," Some unexpected result in Directory_exist function, CommandResult = " .. tostring(CommandResult))
    returnValue = false
  end
  return returnValue
end

-- Find FindExpression in .ini file and replace matched string by parameterName = ValueToUpdate
function common_functions:SetValuesInIniFile(FindExpression, parameterName, ValueToUpdate )
  local SDLini = config.pathToSDL .. "smartDeviceLink.ini"

  f = assert(io.open(SDLini, "r"))
  if f then
    fileContent = f:read("*all")

    fileContentFind = fileContent:match(FindExpression)

    local StringToReplace

    if ValueToUpdate == ";" then
      StringToReplace = ";" .. tostring(parameterName).. " = \n"
    else
      StringToReplace = tostring(parameterName) .. " = " .. tostring(ValueToUpdate) .. "\n"
    end

    if fileContentFind then
      fileContentUpdated = string.gsub(fileContent, FindExpression, StringToReplace)

      f = assert(io.open(SDLini, "w"))
      f:write(fileContentUpdated)
    else
      common_functions:UserPrint(31, "Finding of '" .. tostring(parameterName) .. " = value' is failed. Expect string finding and replacing the value to " .. tostring(ValueToUpdate))
    end
    f:close()
  end
end

--------------------------------------------------------------------------------
-- Update PendingRequestsAmount in .ini file to test TOO_MANY_PENDING_REQUESTS resultCode
--------------------------------------------------------------------------------
function common_functions:SetValuesInIniFile_PendingRequestsAmount(ValueToUpdate)
  common_functions:SetValuesInIniFile("%p?PendingRequestsAmount%s?=%s-[%d]-%s-\n", "PendingRequestsAmount", ValueToUpdate)
end

-- Get value of parameter in "smartDeviceLink.ini"
function common_functions:GetValueFromIniFile(parameter_name)
  find_result = string.find (config.pathToSDL, '.$')
  if string.sub(config.pathToSDL,find_result) ~= "/" then
    config.pathToSDL = config.pathToSDL..tostring("/")
  end
  local file = io.open(config.pathToSDL .. "smartDeviceLink.ini", "r")
  local value = ""
  while true do
    local line = file:read()
    if line == nil then break end
    if string.find(line, parameter_name) ~= nil then
      value = string.sub(line, string.find(line, "=") + 2 , string.len(line))
      break
    end
  end
  file:close()
  if value == "" then
    common_functions:PrintError(" smartDeviceLink.ini does not have parameter name: " .. tostring(parameter_name))
  end
  return value
end

-- Replace a string in "smartDeviceLink.ini" by other string
function common_functions:ReplaceStringInIniFile(originalString, replacedString)
  local iniFilePath = config.pathToSDL .. "smartDeviceLink.ini"
  local iniFile = io.open(iniFilePath, "r")
  sContent = ""
  if iniFile then
    for line in iniFile:lines() do
      if line:match(originalString) then
        line = string.gsub( line, originalString, replacedString )
        sContent = sContent .. line ..'\n'
      else
        sContent = sContent .. line .. '\n'
      end
    end
  end
  iniFile:close()
  iniFile = io.open(iniFilePath, "w")
  iniFile:write(sContent)
  iniFile:close()
end

-- function to update config.lua
function common_functions:UpdateConfigFile(paramName, valueToSet)
  local PathToConfig = "./modules/config.lua"
  f = assert(io.open("./modules/config.lua", "r"))
  fileContent = f:read("*all")
  if type(valueToSet) == number then
    WhitespaceChar, fileContentTextFields = fileContent:match("(%s?)(" .. paramName .. "%s?=%s?%d+)%s?\n")
  else
    WhitespaceChar, fileContentTextFields = fileContent:match("(%s?)(" .. paramName .. "%s?=%s?[%w\"\"]+)%s?\n")
  end
  StringToReplace = paramName .. " = ".. tostring(valueToSet)
  if not fileContentTextFields then
    common_functions:PrintError(paramName .. " is not found in config.lua")
  else
    fileContentUpdated = string.gsub(fileContent, fileContentTextFields, StringToReplace)
    f = assert(io.open(PathToConfig, "w"))
    f:write(fileContentUpdated)
    f:close()
  end
end

-- COMMON FUNCTIONS FOR JSON FILE
--------------------------------------------------------------------------------
-- Make reserve copy of file (FileName) in /bin folder
-- @param file_name: file name will be backed up
--------------------------------------------------------------------------------
function common_functions:BackupFile(file_name)
  os.execute(" cp " .. config.pathToSDL .. file_name .. " " .. config.pathToSDL .. file_name .. "_origin" )
end
--------------------------------------------------------------------------------
-- Restore origin of file (FileName) in /bin folder
-- @param file_name: file name will be backed up
-- @param is_removed_backed_up_file: true: remove backed up file, otherwise, does not remove.
--------------------------------------------------------------------------------
function common_functions:RestoreFile(file_name, is_removed_backed_up_file)
  os.execute(" cp " .. config.pathToSDL .. file_name .. "_origin " .. config.pathToSDL .. file_name )
  if is_removed_backed_up_file then
    os.execute( " rm -f " .. config.pathToSDL .. file_name .. "_origin" )
  end
end

--------------------------------------------------------------------------------
-- Add items into json file
-- @param json_file: file name of a JSON file to be added new items
-- @param parent_item: it will be added new items in added_json_items
-- @param added_json_items: it is a table contains items to be added to json file
--------------------------------------------------------------------------------
function common_functions:AddItemsIntoJsonFile(json_file, parent_item, added_json_items)
  local match_result = "null"
  local temp_replace_value = "\"Temporary_Text\""
  local file = io.open(json_file, "r")
  local json_data = file:read("*all")
  file:close()
  json_data = string.gsub(json_data, match_result, temp_replace_value)
  local json = require("modules/json")
  local data = json.decode(json_data)
  -- Go to parent item
  local parent = data
  for i = 1, #parent_item do
    if not parent[parent_item[i]] then
      parent[parent_item[i]] = {}
    end
    parent = parent[parent_item[i]]
  end
  if type(added_json_items) == "string" then
    added_json_items = json.decode(added_json_items)
  end
  -- Add new items as child items of parent item.
  for k, v in pairs(added_json_items) do
    parent[k] = v
  end
  data = json.encode(data)
  data = string.gsub(data, temp_replace_value, match_result)
  file = io.open(json_file, "w")
  file:write(data)
  file:close()
end

--------------------------------------------------------------------------------
-- Get parameter's value from json file
-- @param json_file: file name of a JSON file
-- @param path_to_parameter: full path of parameter
-- Example: path for Location1 parameter: {"policy", functional_groupings, "Location1"}
--------------------------------------------------------------------------------
function common_functions:GetParameterValueInJsonFile(json_file, path_to_parameter)
  local file = io.open(json_file, "r")
  if not file then
    common_functions:PrintError("Open " .. json_file .. " unsuccessfully")
    return nil
  end
  local json_data = file:read("*all")
  file:close()
  if json_data == "" then
    common_functions:PrintError("There is no data in " .. json_file .. " file")
    return nil
  end
  local json = require("modules/json")
  local data = json.decode(json_data)
  local parameter = data
  for i = 1, #path_to_parameter do
    parameter = parameter[path_to_parameter[i]]
  end
  return parameter
end

--------------------------------------------------------------------------------
-- Remove items into json file
-- @param json_file: file name of a JSON file to be removed items
-- @param parent_item: it will be remove items
-- @param removed_items: it is a array of items will be removed
--------------------------------------------------------------------------------
function common_functions:RemoveItemsFromJsonFile(json_file, parent_item, removed_items)
  local match_result = "null"
  local temp_replace_value = "\"Temporary_Text\""
  local file = io.open(json_file, "r")
  local json_data = file:read("*all")
  file:close()
  json_data = string.gsub(json_data, match_result, temp_replace_value)
  local json = require("modules/json")
  local data = json.decode(json_data)
  -- Go to parent item
  local parent = data
  for i = 1, #parent_item do
    if not parent[parent_item[i]] then
      parent[parent_item[i]] = {}
    end
    parent = parent[parent_item[i]]
  end
  -- Remove items
  for i = 1, #removed_items do
    parent[removed_items[i]] = nil
  end
  data = json.encode(data)
  data = string.gsub(data, temp_replace_value, match_result)
  file = io.open(json_file, "w")
  file:write(data)
  file:close()
end
--------------------------------------------------------------------------------
-- Get items from json file
-- @param json_file: file name of a JSON file
-- @param parent_item: contains the value want to get
--------------------------------------------------------------------------------
function common_functions:GetItemsFromJsonFile(json_file, parent_item)
  if not self:IsFileExist(json_file) then
    common_functions:PrintError("File is not existed")
    return
  end
  local file = io.open(json_file, "r")
  local json_data = file:read("*all")
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)
  local value = data
  for i = 1, #parent_item do
    if not value[parent_item[i]] then
      return nil
    end
    value = value[parent_item[i]]
  end
  return value
end
--------------------------------------------------------------------------------
-- Compare 2 JSON files
-- @param file_name1: file name of the first file
-- @param file_name2: file name of the second file
-- @param compared_specified_item: specify item on json to compare. Example: {"policy_table", "functional_groupings", "funtional_group1"}
-- If it is omitted, compare all items.
--------------------------------------------------------------------------------
function common_functions:CompareJsonFiles(file_name1, file_name2, compared_specified_item)
  local file1 = io.open(file_name1, "r")
  local data1 = file1:read("*all")
  file1:close()
  local file2 = io.open(file_name2, "r")
  local data2 = file2:read("*all")
  file2:close()
  local json = require("modules/json")
  local json_data1 = json.decode(data1)
  local json_data2 = json.decode(data2)
  -- Go to specified item
  for i = 1, #compared_specified_item do
    json_data1 = json_data1[compared_specified_item[i]]
    json_data2 = json_data2[compared_specified_item[i]]
  end
  return common_functions:CompareTables(json_data1,json_data2)
end

-- COMMON FUNCTIONS FOR POLICY TABLE
--------------------------------------------------------------------------------
-- Query policy table database policy.sqlite
-- @param sdl_query: sql query in format: "select <field name1, field name 2, ..> from <table name> where <field name n> = <value>".
-- Example: "\"select entity_type from entities where group_id = 123\""
-- @param parent_item: it will be remove items
-- @param removed_items: it is a array of items will be removed
--------------------------------------------------------------------------------
function common_functions:QueryPolicyDataBase(sdl_query)
  sdl_query = "\"" .. sdl_query .. "\""
  -- Look for policy.sqlite file
  local policy_file1 = config.pathToSDL .. "storage/policy.sqlite"
  local policy_file2 = config.pathToSDL .. "policy.sqlite"
  local policy_file
  if common_functions:IsFileExist(policy_file1) then
    policy_file = policy_file1
  elseif common_functions:IsFileExist(policy_file2) then
    policy_file = policy_file2
  else
    common_functions:PrintError("policy.sqlite file is not exist")
  end
  if policy_file then
    local temp_file = config.pathToSDL .. "temp_policy.sqlite"
    os.execute("cp -f " .. policy_file .. " " .. temp_file)
    local ful_sql_query = "sqlite3 " .. temp_file .. " " .. sdl_query
    local handler = io.popen(ful_sql_query, 'r')
    os.execute("sleep 1")
    local result = handler:read( '*l' )
    handler:close()
    os.execute("mv -f " .. temp_file .. " " .. policy_file)
    return result
  end
end

-- COMMON FUNCTIONS FOR INTERNAL DB OF ATF SCRIPTS
--------------------------------------------------------------------------------
-- Precondition steps:
-- @param modified_parameters: a table contains parameter that need updated new value
-- @param default_app_parameters: default parameters such as config.application1.registerAppInterfaceParams.
--------------------------------------------------------------------------------
function common_functions:CreateRegisterAppParameters(modified_parameters, default_app_parameters)
  local app = common_functions:CloneTable(config.application1.registerAppInterfaceParams)
  default_app_parameters = default_app_parameters or app
  for k, v in pairs(modified_parameters) do
    app[k] = v
  end
  return app
end

--------------------------------------------------------------------------------
-- Get mobile connection name
-- @param mobile_session_name: name of session to get mobile connection name
--------------------------------------------------------------------------------
function common_functions:GetMobileConnectionName(mobile_session_name, self)
  for k_mobile_connection_name, v_mobile_connection_data in pairs(self.mobile_connections) do
    for k_mobile_session_name, v_mobile_session_data in pairs(v_mobile_connection_data) do
      if k_mobile_session_name == mobile_session_name then
        return k_mobile_connection_name
      end
    end
  end
  return nil
end
--------------------------------------------------------------------------------
-- Get application name on a mobile connection
-- @param mobile_session_name: name of session to get mobile connection name
--------------------------------------------------------------------------------
function common_functions:GetApplicationName(mobile_session_name, self)
  for k_mobile_connection_name, v_mobile_connection_data in pairs(self.mobile_connections) do
    for k_mobile_session_name, v_mobile_session_data in pairs(v_mobile_connection_data) do
      if k_mobile_session_name == mobile_session_name then
        for k_application_name, k_application_data in pairs(v_mobile_session_data) do
          return k_application_name
        end
      end -- if k_mobile_session_name
    end -- for k_mobile_session_name
  end -- for k_mobile_connection_name
  common_functions:PrintError("'" .. mobile_session_name .. "' session is not exist so that application name is not found.")
  return nil
end
--------------------------------------------------------------------------------
-- Get mobile connection name and mobile session name of an application,
-- @param app_name: name of application to get mobile session name
--------------------------------------------------------------------------------
function common_functions:GetMobileConnectionNameAndSessionName(app_name, self)
  for k_mobile_connection_name, v_mobile_connection_data in pairs(self.mobile_connections) do
    for k_mobile_session_name, v_mobile_session_data in pairs(v_mobile_connection_data) do
      for k_application_name, v_application_data in pairs(v_mobile_session_data) do
        if k_application_name == app_name then
          return k_mobile_connection_name, k_mobile_session_name
        end
      end
    end
  end
  common_functions:PrintError("'" .. app_name .. "' application is not exist so that mobile session is not found.")
  return nil
end
--------------------------------------------------------------------------------
-- Get HMI app ID of current app in a session
-- @param app_name: name of application to get corresponding HMI app ID
--------------------------------------------------------------------------------
function common_functions:GetHmiAppId(app_name, self)
  local mobile_connection_name, mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(app_name, self)
  local application = self.mobile_connections[mobile_connection_name][mobile_session_name][app_name]
  if not application.is_unregistered then
    return application.hmi_app_id
  else
    return nil
  end
end
--------------------------------------------------------------------------------
-- Get list of HMI app IDs of existing applications (applications have been registered and have not been unregistered yet).
--------------------------------------------------------------------------------
function common_functions:GetHmiAppIds(self)
  local hmi_app_ids = {}
  for k_mobile_connection_name, v_mobile_connection_data in pairs(self.mobile_connections) do
    for k_mobile_session_name, v_mobile_session_data in pairs(v_mobile_connection_data) do
      for k_application_name, v_application_data in pairs(v_mobile_session_data) do
        if not v_application_data.is_unregistered then
          hmi_app_ids[#hmi_app_ids + 1] = k_application_name
        end
      end
    end
  end
  return hmi_app_ids
end
--------------------------------------------------------------------------------
-- Get list of applications that were registered
--------------------------------------------------------------------------------
function common_functions:GetRegisteredApplicationNames(self)
  local app_names = {}
  for k_mobile_connection_name, v_mobile_connection_data in pairs(self.mobile_connections) do
    for k_mobile_session_name, v_mobile_session_data in pairs(v_mobile_connection_data) do
      for k_application_name, v_application_data in pairs(v_mobile_session_data) do
        if not v_application_data.is_unregistered then
          app_names[#app_names + 1] = k_application_name
        end
      end
    end
  end
  return app_names
end
--------------------------------------------------------------------------------
-- Get parameter value of current app in a session
-- @param mobile_connect_name: name of mobile session
-- @param app_name: name of application
--------------------------------------------------------------------------------
function common_functions:GetAppParameter(app_name, queried_parameter_name, self)
  local mobile_connection_name, mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(app_name, self)
  local application = self.mobile_connections[mobile_connection_name][mobile_session_name][app_name]
  return application.register_application_parameters[queried_parameter_name]
end
--------------------------------------------------------------------------------
-- Check application is media or not
-- @param app_name: name of application
--------------------------------------------------------------------------------
function common_functions:IsMediaApp(app_name, self)
  local is_media = common_functions:GetAppParameter(app_name, "isMediaApplication", self)
  local app_hmi_types = common_functions:GetAppParameter(app_name, "appHMIType", self)
  for i = 1, #app_hmi_types do
    if (app_hmi_types[i] == "COMMUNICATION") or (app_hmi_types[i] == "NAVIGATION") or (app_hmi_types[i] == "MEDIA") then
      is_media = true
    end
  end
  return is_media
end
--------------------------------------------------------------------------------
-- Store mobile connect data to use later
-- @param mobile_connection_name: name of connection that is used by ATF
--------------------------------------------------------------------------------
function common_functions:StoreConnectionData(mobile_connection_name, self)
  if not self.mobile_connections then
    self.mobile_connections = {}
  end
  self.mobile_connections[mobile_connection_name] = {}
end
--------------------------------------------------------------------------------
-- Check connection is exist or not
-- @param mobile_connection_name: name of connection that is used by ATF
--------------------------------------------------------------------------------
function common_functions:IsConnectionDataExist(mobile_connection_name, self)
  if not self.mobile_connections then
    self.mobile_connections = {}
  end
  if not self.mobile_connections[mobile_connection_name] then
    return false
  end
  return true
end
--------------------------------------------------------------------------------
-- Store session data to use later
-- @param mobile_connection_name: name of mobile connection
-- @param mobile_session_name: name of session
--------------------------------------------------------------------------------
function common_functions:StoreSessionData(mobile_connection_name, mobile_session_name, self)
  self.mobile_connections[mobile_connection_name][mobile_session_name] = {}
end
--------------------------------------------------------------------------------
-- Store new application data to use later for activate application, unregister, ..
-- @param mobile_session_name:
-- @param app_name:
--------------------------------------------------------------------------------
function common_functions:StoreApplicationData(mobile_session_name, app_name, application_parameters, hmi_app_id, self)
  local mobile_connection_name = common_functions:GetMobileConnectionName(mobile_session_name, self)
  self.mobile_connections[mobile_connection_name][mobile_session_name][app_name] = {
    register_application_parameters = application_parameters,
    hmi_app_id = hmi_app_id,
    is_unregistered = false
  }
end
--------------------------------------------------------------------------------
-- Set status of application is unregistered
-- @param app_name: name of application is unregistered
--------------------------------------------------------------------------------
function common_functions:SetApplicationStatusIsUnRegistered(app_name, self)
  local mobile_connection_name, mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(app_name, self)
  self.mobile_connections[mobile_connection_name][mobile_session_name][app_name].is_unregistered = true
end
--------------------------------------------------------------------------------
-- Store HMISatatus for application to use later
-- @param app_name: name of application
-- @param on_hmi_status: HMI status such as {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
-- @param self: "self" object in side a Test.
--------------------------------------------------------------------------------
function common_functions:StoreHmiStatus(app_name, on_hmi_status, self)
  local mobile_connection_name, mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(app_name, self)
  local application = self.mobile_connections[mobile_connection_name][mobile_session_name][app_name]
  if not application.on_hmi_status then
    application.on_hmi_status = {}
  end
  -- Set value from on_hmi_status to data of application.
  for k, v in pairs(on_hmi_status) do
    application.on_hmi_status[k] = v
  end
end
--------------------------------------------------------------------------------
-- Get HMISatatus for application from stored data.
-- @param app_name: name of application
-- @param self: "self" object in side a Test.
-- @param specific_parameter_name: It can be hmiLevel, audioStreamingState and systemContext.
-- If it is omitted, return all parameters such as {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
--------------------------------------------------------------------------------
function common_functions:GetHmiStatus(app_name, self, specific_parameter_name)
  local mobile_connection_name, mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(app_name, self)
  local application = self.mobile_connections[mobile_connection_name][mobile_session_name][app_name]
  if specific_parameter_name then
    return application.on_hmi_status[specific_parameter_name]
  else
    return application.on_hmi_status
  end
end

-- COMMON FUNCTIONS TO USE IN STEPS
--------------------------------------------------------------------------------
-- Print error message on ATF script console
-- @param error_message: message to be printed.
--------------------------------------------------------------------------------
function common_functions:PrintError(error_message)
  print(" \27[31m " .. error_message .. " \27[0m ")
end
--------------------------------------------------------------------------------
-- Delay to verify expected result
-- @param time: time in seconds for delay verifying expected result
--------------------------------------------------------------------------------
function common_functions:DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time+1000)

  function raise_event()
    RAISE_EVENT(event, event)
  end

  RUN_AFTER(raise_event, time)
end

-- COMMON FUNCTIONS TO STRING
function common_functions:CreateString(length)
  return string.rep("a", length)
end

function common_functions:CreateArrayString(size, length)
  length = length or 1
  local temp = {}
  for i = 1, size do
    table.insert(temp, string.rep("a", length))
  end
  return temp
end

-- COMMON FUNCTIONS TO TABLE
function common_functions:ConvertTableToString(tbl, i)
  local strIndex = ""
  local strIndex2 = ""
  local strReturn = ""
  for j = 1, i do
    strIndex = strIndex .. "\t"
  end
  strIndex2 = strIndex .."\t"
  local x = 0
  if type(tbl) == "table" then
    strReturn = strReturn .. strIndex .. "{\n"
    for k,v in pairs(tbl) do
      x = x + 1
      if type(k) == "number" then
        if type(v) == "table" then
          if x ==1 then
          else
            strReturn = strReturn .. ",\n"
          end
        else
          if x ==1 then
            strReturn = strReturn .. strIndex2
          else
            strReturn = strReturn .. ",\n" .. strIndex2
          end
        end
      else
        if x ==1 then
          strReturn = strReturn .. strIndex2 .. k .. " = "
        else
          strReturn = strReturn .. ",\n" .. strIndex2 .. k .. " = "
        end
        if type(v) == "table" then
          strReturn = strReturn .. "\n"
        end
      end
      strReturn = strReturn .. common_functions:ConvertTableToString(v, i+1)
    end
    strReturn = strReturn .. "\n"
    strReturn = strReturn .. strIndex .. "}"
  else
    if type(tbl) == "number" then
      strReturn = strReturn .. tbl
    elseif type(tbl) == "boolean" then
      strReturn = strReturn .. tostring(tbl)
    elseif type(tbl) == "string" then
      strReturn = strReturn .."\"".. tbl .."\""
    end
  end
  return strReturn
end

function common_functions:PrintTable(tbl)
  print ("-------------------------------------------------------------------")
  print (common_functions:ConvertTableToString (tbl, 1))
  print ("-------------------------------------------------------------------")
end

function common_functions:CloneTable(original)
  local orig_type = type(original)
  local copy
  if orig_type == 'table' then
    copy = {}
    for k, v in pairs(original) do
      if type(v) == 'table' then
        v = common_functions:CloneTable(v)
      end
      copy[k] = v
    end
  else
    copy = original
  end
  return copy
end

function common_functions:CompareTables(t1,t2)
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then return false end
  -- non-table types can be directly compared
  if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
  for k1,v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil or not common_functions:CompareTables(v1,v2) then return false end
  end
  for k2,v2 in pairs(t2) do
    local v1 = t1[k2]
    if v1 == nil or not common_functions:CompareTables(v1,v2) then return false end
  end
  return true
end

function common_functions:CompareTablesNotSorted(table1,table2)
  local t1 = common_functions:CloneTable(table1)
  local t2 = common_functions:CloneTable(table2)
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then
    return false
  end
  -- non-table types can be directly compared
  if ty1 ~= 'table' and ty2 ~= 'table' then
    return t1 == t2
  end
  -- find each item of table t1 on table t2. if find, remove this item on both table
  local total_find_items_of_table1 = 0
  local number_of_items_on_table1 = 0
  for k1, v1 in pairs(t1) do
    number_of_items_on_table1 = number_of_items_on_table1 + 1
    local v2 = t2[k1]
    if type(k1) == 'number' then
      -- compare array with care about order
      -- find v1 in array t2
      local find = false
      for k2, v2 in pairs (t2) do
        if type(k2) == 'number' then
          if common_functions:CompareTablesNotSorted(v1, v2) then
            find = true
            total_find_items_of_table1 = total_find_items_of_table1 + 1
            t2[k2] = nil
            break
          end
        end
      end

      if find == false then -- if v1 is not found in array t2
        return false
      end

    else
      if v2 == nil then
        return false
      end
      if common_functions:CompareTablesNotSorted(v1,v2) then -- found v1 = v2
        total_find_items_of_table1 = total_find_items_of_table1 + 1
        t2[k1] = nil
      end
    end
    if total_find_items_of_table1 == number_of_items_on_table1 then
    end
  end

  local rest_items_on_table2 = 0
  for k2, v2 in pairs(t2) do
    rest_items_on_table2 = rest_items_on_table2 + 1
  end
  return total_find_items_of_table1 == number_of_items_on_table1 and rest_items_on_table2 == 0

end

-- Check if specified value (which also may be a table) is present in a table.
-- @param value: checked value, may be a table
-- @param searched_table: table where a value will be searched in
-- @example: Find("find", { { "find" } }) -> true
function common_functions:Find(value, searched_table)
  if common_functions:CompareTables(value, searched_table) then
    return true
  end
  if type(searched_table) ~= "table" then
    return false
  end
  for _, v in pairs(searched_table) do
    if common_functions:Find(value, v) then
      return true
    end
  end
  return false
end

-- COMMON FUNCTIONS TO SDL
--------------------------------------------------------------------------------
-- Make reserve copy of file (FileName) in /bin folder
-- @param file_name: file name will be backed up
--------------------------------------------------------------------------------
function common_functions:KillAllSdlProcesses()
  os.execute(" kill -9 $(ps aux | grep -e smartDeviceLinkCore | awk '{print$2}')" )
end

function common_functions:CheckSdlPath()
  --Verify config.pathToSDL
  findresultFirstCharacters = string.match (config.pathToSDL, '^%.%/')
  if findresultFirstCharacters == "./" then
    local CurrentFolder = assert( io.popen( "pwd" , 'r'))
    local CurrentFolderPath = CurrentFolder:read( '*l' )
    PathUsingCurrentFolder = string.match (config.pathToSDL, '[^%.]+')
    config.pathToSDL = CurrentFolderPath .. PathUsingCurrentFolder
  end
  findresultLastCharacters = string.find (config.pathToSDL, '.$')
  if string.sub(config.pathToSDL,findresultLastCharacters) ~= "/" then
    config.pathToSDL = config.pathToSDL..tostring("/")
  end
end

function common_functions:UserPrint(color, message, delimeter)
  delimeter = delimeter or "\n"
  io.write("\27[" .. tostring(color) .. "m" .. tostring(message) .. "\27[0m", delimeter)
end

function common_functions:CreateIntegersArray(value, size)
  value = value or 1
  size = size or 1
  local temp = {}
  for i = 1, size do
    table.insert(temp, value)
  end
  return temp
end

function common_functions:CreateStructsArray(structure, size)
  size = size or 1
  local temp = {}
  for i = 1, size do
    table.insert(temp, structure)
  end
  return temp
end

function common_functions:PrintError(errorMessage)
  print()
  print(" \27[31m " .. errorMessage .. " \27[0m ")
end

function common_functions:StoreHmiAppId(app_name, hmi_app_id, self)
  local mobile_connection_name, mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(app_name, self)
  self.mobile_connections[mobile_connection_name][mobile_session_name][app_name].hmi_app_id = hmi_app_id
end

-----------------------------------------------------------------------------
-- Remove a test function from Test module
-- @param test_name: name of test function
-- @param test_module: Test module that contains list of tests.
-----------------------------------------------------------------------------
function common_functions:RemoveTest(test_name, test_module)
  local test_function
  for k_test_function, v_test_name in pairs(test_module.case_names) do
    if v_test_name == test_name then
      test_function = k_test_function
      break
    end
  end
  local test_number = #test_module.test_cases + 1
  for i = 1, #test_module.test_cases do
    if test_module.test_cases[i] == test_function then
      test_number = i
      break
    end
  end
  -- remove test
  if test_function then
    test_module.case_names[test_function] = nil
    for i = test_number, #test_module.test_cases do
      if i == #test_module.test_cases then
        test_module.test_cases[i] = nil
      else
        test_module.test_cases[i] = test_module.test_cases[i + 1]
      end
    end
  end
end

-----------------------------------------------------------------------------
-- Get full path to image
-- @param image_file_name: name of the image
-----------------------------------------------------------------------------
function common_functions:GetFullPathIcon(image_file_name, appId)
  if not appId then
    appId = config.application1.registerAppInterfaceParams.appID
  end
  local full_path_icon = table.concat({config.pathToSDL, "storage/", appId, "_", config.deviceMAC, "/", image_file_name})
  return full_path_icon
end

-----------------------------------------------------------------------------
-- Get value in range
-- @param lower_bound: min value of range
-- @param upper_bound: max value of range
-- @param value_to_check: value to check it is in range
-----------------------------------------------------------------------------
function common_functions:InRange(lower_bound, upper_bound, value_to_check)
  if lower_bound <= value_to_check and value_to_check <= upper_bound then
    return true
  end
  return false
end

return common_functions
