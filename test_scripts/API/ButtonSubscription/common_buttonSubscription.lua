---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")

--[[ Module ]]
local m = actions

--[[ Variables ]]
m.buttons = {
  "OK",
  "PLAY_PAUSE",
  "SEEKLEFT",
  "SEEKRIGHT",
  "TUNEUP",
  "TUNEDOWN",
  "PRESET_0",
  "PRESET_1",
  "PRESET_2",
  "PRESET_3",
  "PRESET_4",
  "PRESET_5",
  "PRESET_6",
  "PRESET_7",
  "PRESET_8",
  "PRESET_9",
  "SEARCH"
}

--[[ Functions ]]
function m.rpcSuccess(pAppId, pRpc, pButtonName)
  local cid = m.getMobileSession(pAppId):SendRPC(pRpc, { buttonName = pButtonName })
  EXPECT_HMICALL("Buttons." .. pRpc,{ appID = m.getHMIAppId(pAppId), buttonName = pButtonName })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
end

function m.rpcUnsuccess(pAppId, pRpc, pButtonName, pResultCode)
  local cid = m.getMobileSession(pAppId):SendRPC(pRpc, { buttonName = pButtonName })
  EXPECT_HMICALL("Buttons." .. pRpc,{ appID = m.getHMIAppId(pAppId), buttonName = pButtonName })
    :Times(0)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = pResultCode })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
    :Times(0)
end

function m.buttonPress(pAppId, pButtonName)
  m.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButtonName, mode = "BUTTONDOWN", appID = m.getHMIAppId(pAppId) })
  m.getHMIConnection():SendNotification("Buttons.OnButtonPress",
    { name = pButtonName, mode = "SHORT", appID = m.getHMIAppId(pAppId) })
  m.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButtonName, mode = "BUTTONUP", appID = m.getHMIAppId(pAppId) })
  m.getMobileSession(pAppId):ExpectNotification( "OnButtonEvent",
    { buttonName = pButtonName, buttonEventMode = "BUTTONDOWN"},
    { buttonName = pButtonName, buttonEventMode = "BUTTONUP"})
    :Times(2)
  m.getMobileSession(pAppId):ExpectNotification( "OnButtonPress",
    { buttonName = pButtonName, buttonPressMode = "SHORT"})
end

return m
