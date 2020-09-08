  ---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0085-submenu-icon.md
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) Mobile application sends AddSubMenu request to SDL with "menuIcon"= icon.png
-- ("Icon.png" is missing on the system, it was not added via PutFile)
-- SDL does:
-- 1) resend request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SubMenuIcon/commonSubMenuIcon')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  menuID = 1000,
  position = 500,
  menuName ="SubMenupositive",
  menuIcon = {
    imageType = "DYNAMIC",
    value = "icon.png"
  }
}

local requestUiParams = {
  menuID = requestParams.menuID,
  menuParams = {
    position = requestParams.position,
    menuName = requestParams.menuName
  },
  menuIcon = {
    imageType = "DYNAMIC",
    value =  common.getPathToFileInStorage("icon.png")
  }
}

--[[ Local Functions ]]
local function menuIconNotExistingFile()
  local corId = common.getMobileSession():SendRPC("AddSubMenu", requestParams)
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu", requestUiParams)
  :Do(function(_,data)
      common.getHMIConnection():SendError(data.id, data.method, "WARNINGS", "Requested image(s) not found")
    end)
  common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "WARNINGS",
    info = "Requested image(s) not found"})
  common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("Activate Application", common.activateApp)

runner.Title("Test")
runner.Step("MenuIcon with result code WARNINGS", menuIconNotExistingFile)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
