---------------------------------------------------------------------------------------------------
-- Smoke API common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.mobileHost = "127.0.0.1"
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local json = require("modules/json")

local consts = require("user_modules/consts")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require('user_modules/utils')
local actions = require('user_modules/sequences/actions')
local SDL = require("SDL")

SDL.buildOptions.remoteControl = "OFF"
SDL.buildOptions.extendedPolicy = "EXTERNAL_PROPRIETARY"

--[[ Local Variables ]]
local events = require("events")
local sdl = require("SDL")

--[[ Local Variables ]]
local hmiAppIds = {}
local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

local commonSmoke = {}

commonSmoke.HMITypeStatus = {
  NAVIGATION = false,
  COMMUNICATION = false
}
commonSmoke.timeout = 5000
commonSmoke.minTimeout = 500

local function allowSDL(self)
  local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
    {language = "EN-US", messageCodes = {"DataConsent"}})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function()
    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
    { allowed = true, source = "GUI", device = { id = commonSmoke.getDeviceMAC(), name = commonSmoke.getDeviceName() }})
  end)
end

local function checkIfPTSIsSentAsBinary(bin_data)
  if not (bin_data ~= nil and string.len(bin_data) > 0) then
    commonFunctions:userPrint(consts.color.red,
    "PTS was not sent to Mobile in payload of OnSystemRequest")
  end
end

local function getPTUFromPTS(tbl)
  tbl.policy_table.consumer_friendly_messages.messages = nil
  tbl.policy_table.device_data = nil
  tbl.policy_table.module_meta = nil
  tbl.policy_table.usage_and_error_counts = nil
  tbl.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  tbl.policy_table.module_config.preloaded_pt = nil
  tbl.policy_table.module_config.preloaded_date = nil
end

--[[Module functions]]
function commonSmoke.preconditions()
  commonFunctions:SDLForceStop()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
  commonPreconditions:BackupFile(preloadedPT)
  commonSmoke.updatePreloadedPT()
end

function commonSmoke.getDeviceName()
  return config.mobileHost
end

function commonSmoke.getDeviceMAC()
  local cmd = "echo -n " .. commonSmoke.getDeviceName() .. " | sha256sum | awk '{printf $1}'"
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

function commonSmoke.getPathToSDL()
  return config.pathToSDL
end

function commonSmoke.getMobileAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return config["application" .. pAppId].registerAppInterfaceParams.appID
end

function commonSmoke.getSelfAndParams(...)
  local out = { }
  local selfIdx = nil
  for i,v in pairs({...}) do
    if type(v) == "table" and v.isTest then
      table.insert(out, v)
      selfIdx = i
      break
    end
  end
  local idx = 2
  for i = 1, table.maxn({...}) do
    if i ~= selfIdx then
      out[idx] = ({...})[i]
      idx = idx + 1
    end
  end
  return table.unpack(out, 1, table.maxn(out))
end

function commonSmoke.getHMIAppId(pAppId)
  if not pAppId then pAppId = 1 end
  return hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID]
end

function commonSmoke.getPathToFileInStorage(fileName)
  return commonPreconditions:GetPathToSDL() .. "storage/"
  .. commonSmoke.getMobileAppId() .. "_"
  .. commonSmoke.getDeviceMAC() .. "/" .. fileName
end

function commonSmoke.getMobileSession(pAppId, self)
  self, pAppId = commonSmoke.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  if not self["mobileSession" .. pAppId] then
    self["mobileSession" .. pAppId] = mobile_session.MobileSession(self, self.mobileConnection)
  end
  return self["mobileSession" .. pAppId]
end

function commonSmoke.getSmokeAppPoliciesConfig()
  return {
    keep_context = true,
    steal_focus = true,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4", "Emergency-1" },
    RequestType = {
      "LAUNCH_APP",
      "QUERY_APPS",
      "PROPRIETARY"
    }
  }
end

--[[ @updatePTU: update PTU with application data
--! @parameters:
--! tbl - table with data for policy table update
--! @return: none
--]]
local function updatePTU(tbl, pAppId)
  if  not pAppId then pAppId = 1 end
  tbl.policy_table.app_policies[config["application" .. pAppId].registerAppInterfaceParams.appID] = commonSmoke.getSmokeAppPoliciesConfig()
end

function commonSmoke.splitString(inputStr, sep)
  if sep == nil then
    sep = "%s"
  end
  local splitted, i = {}, 1
  for str in string.gmatch(inputStr, "([^"..sep.."]+)") do
    splitted[i] = str
    i = i + 1
  end
  return splitted
end

function commonSmoke.expectOnHMIStatusWithAudioStateChanged(self, pAppId, request, level)
  if pAppId == nil then pAppId = 1 end
  if request == nil then request = "BOTH" end
  if level == nil then level = "FULL" end

  local mobSession = commonSmoke.getMobileSession(pAppId, self)
  local appParams = config["application" .. pAppId].registerAppInterfaceParams

  if appParams.isMediaApplication == true then
    if request == "BOTH" then
      mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE" },
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "ATTENUATED" },
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE" },
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE" })
      :Times(4)
    elseif request == "speak" then
      mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED" },
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE" })
      :Times(2)
    elseif request == "alert" then
      mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE" },
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE" })
      :Times(2)
    end
  elseif appParams.isMediaApplication == false then
    if request == "BOTH" then
      mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" },
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" })
      :Times(2)
    elseif request == "speak" then
      mobSession:ExpectNotification("OnHMIStatus")
      :Times(0)
    elseif request == "alert" then
      mobSession:ExpectNotification("OnHMIStatus",
        { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" },
        { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" })
      :Times(2)
    end
  end

end

function commonSmoke.activateApp(pAppId, self)
  self, pAppId = commonSmoke.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  local pHMIAppId = hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID]
  local mobSession = commonSmoke.getMobileSession(pAppId, self)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIAppId })
  EXPECT_HMIRESPONSE(requestId)
  mobSession:ExpectNotification("OnHMIStatus",
    {hmiLevel = "FULL", audioStreamingState = commonSmoke.GetAudibleState(pAppId), systemContext = "MAIN"})
  mobSession:ExpectNotification("OnDriverDistraction")
  commonTestCases:DelayedExp(commonSmoke.minTimeout)
end

function commonSmoke.start(pHMIParams, self)
  self, pHMIParams = commonSmoke.getSelfAndParams(pHMIParams, self)
  self:runSDL()
  commonFunctions:waitForSDLStart(self)
  :Do(function()
    self:initHMI(self)
    :Do(function()
      commonFunctions:userPrint(consts.color.magenta, "HMI initialized")
      self:initHMI_onReady(pHMIParams)
      :Do(function()
        commonFunctions:userPrint(consts.color.magenta, "HMI is ready")
        self.hmiConnection:SendNotification("UI.OnDriverDistraction", { state = "DD_OFF" })
        self:connectMobile()
        :Do(function()
          commonFunctions:userPrint(consts.color.magenta, "Mobile connected")
          allowSDL(self)
        end)
      end)
    end)
  end)
end

-- Expect 3 OnStatusUpdate notification on HMI side during PTU
local function expOnStatusUpdate()
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, {status = "UP_TO_DATE" })
  :Times(3)
end

-- Convert snapshot form json to table
-- @tparam file pts_f snapshot file
local function ptsToTable(pts_f)
  local f = io.open(pts_f, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

-- Save created PT in file
-- @tparam table pPtu PT table
-- @tparam string ptu_file_name file name
local function storePTUInFile(pPtu, ptu_file_name)
  local f = io.open(ptu_file_name, "w")
  f:write(json.encode(pPtu))
  f:close()
end

-- Fail test cases by incorrect PTU
-- @tparam string pRequestName request name of RPC that is failed expectations
local function failInCaseIncorrectPTU(pRequestName, self)
  self:FailTestCase(pRequestName .. " was sent more than once (PTU update was incorrect)")
end

-- Policy table update with Proprietary flow
-- @tparam table pPtu_table PT table
-- @tparam string pFlow policy flow
local function ptuProprietary(pPtu_table, self, pFlow, pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = commonSmoke.getMobileSession(pAppId, self)
  -- Get path to snapshot
  local pts_file_name = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
  .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  -- create ptu_file_name as tmp file
  local ptu_file_name = os.tmpname()
  -- Send GetURLS request from HMI to SDL with service 7
  local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  -- Expect response GetURLS on HMI side
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      local pHMIAppId = commonSmoke.getHMIAppId()
      -- After receiving GetURLS response send OnSystemRequest notification from HMI
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = pts_file_name, appID = pHMIAppId })
      -- Prepare PT for update
      getPTUFromPTS(pPtu_table)
      -- Save created PT for update in tmp file
      storePTUInFile(pPtu_table, ptu_file_name)
      -- Expect receiving of OnSystemRequest notification with snapshot on mobile side
      mobSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_, d)
          -- After receiving OnSystemRequest notification on mobile side check that
          -- data in notification was sent as binary data
          checkIfPTSIsSentAsBinary(d.binaryData, pFlow, self)
          -- Send SystemRequest request with PT for update from mobile side
          local corIdSystemRequest = mobSession:SendRPC("SystemRequest",
            { requestType = "PROPRIETARY" }, ptu_file_name)
          -- Expect SystemRequest request on HMI side
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_, dd)
              -- Send SystemRequest response form HMI with resultCode SUCCESS
              self.hmiConnection:SendResponse(dd.id, dd.method, "SUCCESS", { })
              -- Send OnReceivedPolicyUpdate notification from HMI
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                { policyfile = dd.params.fileName })
            end)
          -- Expect SystemRequest response with resultCode SUCCESS on mobile side
          mobSession:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
          -- remove tmp PT file after receiving SystemRequest response on mobile side
          :Do(function() os.remove(ptu_file_name) end)
        end)
    end)
end

-- Policy table update with HTTP flow
-- @tparam table pPtu_table PT table
local function ptuHttp(self, pPtu_table, pAppId)
  if not pAppId then pAppId = 1 end
  local mobSession = commonSmoke.getMobileSession(pAppId, self)
  -- name for PT for SystemRequest
  local policy_file_name = "PolicyTableUpdate"
  -- tmp file name for PT file
  local ptu_file_name = os.tmpname()
  -- Prepare PT for update
  getPTUFromPTS(pPtu_table)
  -- Save created PT for update in tmp file
  storePTUInFile(pPtu_table, ptu_file_name)
  -- Send SystemRequest form mobile app with created PT
  local corId = mobSession:SendRPC("SystemRequest",
    { requestType = "HTTP", fileName = policy_file_name }, ptu_file_name)
  -- Expect successful SystemRequest response on mobile side
  mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  -- remove tmp PT file
  os.remove(ptu_file_name)
end

-- Registration of application with policy table update
local function raiPTU(self, pPT, id)
  self, id, pPT = commonSmoke.getSelfAndParams(id, pPT, self)
  if not id then id = 1 end
  expOnStatusUpdate() -- temp solution due to issue in SDL:
  -- SDL.OnStatusUpdate(UPDATE_NEEDED) notification is sent before BC.OnAppRegistered (EXTERNAL_PROPRIETARY flow)

  -- creation mobile session
  self["mobileSession" .. id] = mobile_session.MobileSession(self, self.mobileConnection)
  -- open RPC service in created session
  self["mobileSession" .. id]:StartService(7)
  :Do(function()
      -- Send RegisterAppInterface request from mobile application
      local corId = self["mobileSession" .. id]:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      -- Expect OnAppRegistered on HMI side from SDL
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config.application1.registerAppInterfaceParams.appName } })
      :Do(function(_, data)
        hmiAppIds[config["application" .. id].registerAppInterfaceParams.appID] = data.params.application.appID
      end)
          if sdl.buildOptions.extendedPolicy == "PROPRIETARY"
          or sdl.buildOptions.extendedPolicy == "EXTERNAL_PROPRIETARY" then
            -- Expect PolicyUpdate request on HMI side
            EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
            :Do(function(e, d)
                if e.occurences == 1 then -- SDL send BC.PolicyUpdate more than once if PTU update was incorrect
                  -- Create PT form snapshot
                  local ptu_table_loc = ptsToTable(d.params.file)
                  updatePTU(ptu_table_loc)
                  if pPT then
                    pPT(ptu_table_loc)
                  end
                  -- Sending PolicyUpdate request from HMI with resultCode SUCCESS
                  self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
                  -- PTU proprietary flow
                  -- print_table(ptu_table_loc)
                  ptuProprietary(ptu_table_loc, self, sdl.buildOptions.extendedPolicy)
                else
                  failInCaseIncorrectPTU("BC.PolicyUpdate", self)
                end
              end)
          elseif sdl.buildOptions.extendedPolicy == "HTTP" then
            -- Expect OnSystemRequest notification on mobile side
            self["mobileSession" .. id]:ExpectNotification("OnSystemRequest")
            :Do(function(e, d)
                if d.payload.requestType == "HTTP" then
                  if e.occurences <= 2 then -- SDL send OnSystemRequest more than once if PTU update was incorrect
                    -- Check data in receives OnSystemRequest notification on mobile side
                    checkIfPTSIsSentAsBinary(d.binaryData, sdl.buildOptions.extendedPolicy, self)
                    if d.binaryData then
                      -- Create PT form binary data
                      local ptu_table_loc = json.decode(d.binaryData)
                      -- PTU HTTP flow
                      ptuHttp(self, ptu_table_loc)
                    end
                  else
                    failInCaseIncorrectPTU("OnSystemRequest", self)
                  end
                end
              end)
            :Times(2)
          end
        -- end)
      -- Expect RegisterAppInterface response on mobile side with resultCode SUCCESS
      self["mobileSession" .. id]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          -- Expect OnHMIStatus with hmiLevel NONE on mobile side form SDL
          self["mobileSession" .. id]:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          -- Expect OnPermissionsChange on mobile side form SDL
          self["mobileSession" .. id]:ExpectNotification("OnPermissionsChange")
          :Times(2)
        end)
    end)
end

function commonSmoke.registerApplicationWithPTU(pAppId, pUpdateFunction, self)
  self, pAppId, pUpdateFunction = commonSmoke.getSelfAndParams(pAppId, pUpdateFunction, self)
  raiPTU(self, pUpdateFunction, pAppId)
end

function commonSmoke.AppActivationForResumption(self, pHMIid)
   local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIid })
  EXPECT_HMIRESPONSE(requestId)
    :Do(function(_,data)
      if
        data.result.isSDLAllowed ~= true then
        local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestId)
        :Do(function()
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            { allowed = true, source = "GUI", device = { id = commonSmoke.getDeviceMAC(), name = commonSmoke.getDeviceName() }})
          local requestId2 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = pHMIid })
          EXPECT_HMIRESPONSE(requestId2)
        end)
      end
    end)
end

function commonSmoke.putFile(params, pAppId, self)
  if not pAppId then pAppId = 1 end
  local mobileSession = commonSmoke.getMobileSession(pAppId, self);
  local cid = mobileSession:SendRPC("PutFile", params.requestParams, params.filePath)

  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

function commonSmoke.SetAppType(HMIType)
  for _,v in pairs(HMIType) do
    if v == "NAVIGATION" then
      commonSmoke.HMITypeStatus["NAVIGATION"] = true
    elseif v == "COMMUNICATION" then
      commonSmoke.HMITypeStatus["COMMUNICATION"] = true
    end
  end
end

function commonSmoke.GetAudibleState(pAppId)
  if not pAppId then pAppId = 1 end
  commonSmoke.SetAppType(config["application" .. pAppId].registerAppInterfaceParams.appHMIType)
  if config["application" .. pAppId].registerAppInterfaceParams.isMediaApplication == true or
    commonSmoke.HMITypeStatus.COMMUNICATION == true or
    commonSmoke.HMITypeStatus.NAVIGATION == true then
    return "AUDIBLE"
  elseif
    config["application" .. pAppId].registerAppInterfaceParams.isMediaApplication == false then
    return "NOT_AUDIBLE"
  end
end

function commonSmoke.GetAppMediaStatus(pAppId)
  if not pAppId then pAppId = 1 end
  local isMediaApplication = config["application" .. pAppId].registerAppInterfaceParams.isMediaApplication
  return isMediaApplication
end

function commonSmoke.readParameterFromSmartDeviceLinkIni(paramName)
  return commonFunctions:read_parameter_from_smart_device_link_ini(paramName)
end

function commonSmoke.postconditions()
  StopSDL()
  commonPreconditions:RestoreFile(preloadedPT)
end

function commonSmoke.updatePreloadedPT()
  local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
  local pt = utils.jsonFileToTable(preloadedFile)
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  local additionalRPCs = {
    "SendLocation", "SubscribeVehicleData", "UnsubscribeVehicleData", "GetVehicleData", "UpdateTurnList",
    "AlertManeuver", "DialNumber", "ReadDID", "GetDTCs", "ShowConstantTBT"
  }
  pt.policy_table.functional_groupings.NewTestCaseGroup = { rpcs = { } }
  for _, v in pairs(additionalRPCs) do
    pt.policy_table.functional_groupings.NewTestCaseGroup.rpcs[v] = {
      hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
    }
  end
  local appID = actions.getConfigAppParams(1).appID
  pt.policy_table.app_policies[appID] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[appID].groups = { "Base-4", "NewTestCaseGroup" }
  pt.policy_table.app_policies[appID].keep_context = true
  pt.policy_table.app_policies[appID].steal_focus = true
  utils.tableToJsonFile(pt, preloadedFile)
end

function commonSmoke.registerApp(pAppId, self)
  self, pAppId = commonSmoke.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  local mobSession = commonSmoke.getMobileSession(pAppId, self)
  mobSession:StartService(7)
  :Do(function()
      local corId = mobSession:SendRPC("RegisterAppInterface", config["application" .. pAppId].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. pAppId].registerAppInterfaceParams.appName } })
      :Do(function(_, data)
          hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID] = data.params.application.appID
        end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          mobSession:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          mobSession:ExpectNotification("OnPermissionsChange"):Times(AtLeast(1))
        end)
    end)
end

function commonSmoke.ShutDown_IGNITION_OFF(self)
  local timeout = 5000
  local function removeSessions()
    for i = 1, actions.getAppsCount() do
      self.mobileSession[i] = nil
    end
  end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  EXPECT_EVENT(event, "SDL shutdown")
  :Do(function()
      removeSessions()
      StopSDL()
      utils.wait(1000)
    end)
  actions.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      actions.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
      for i = 1, actions.getAppsCount() do
        actions.getMobileSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
      end
    end)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(actions.getAppsCount())
  local isSDLShutDownSuccessfully = false
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  :Do(function()
      utils.cprint(35, "SDL was shutdown successfully")
      isSDLShutDownSuccessfully = true
      RAISE_EVENT(event, event)
    end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownSuccessfully == false then
      utils.cprint(35, "SDL was shutdown forcibly")
      RAISE_EVENT(event, event)
    end
  end
  RUN_AFTER(forceStopSDL, timeout + 500)
end

return commonSmoke
