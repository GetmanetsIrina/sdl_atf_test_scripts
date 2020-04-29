---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL receive GENERIC_ERROR to GetVehicleDate request if HMI response is invalid
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC GetVehicleData is allowed by policies
-- 3) App is registered
-- Steps:
-- 1) App sends valid GetVehicleData request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- Steps:
-- 2) HMI response is invalid
-- SDL does:
-- - a) send GetVehicleData response with (success = false, resultCode = GENERIC_ERROR") to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Function ]]
local function getVDHMIInvalidResponse()
  local cid = common.getMobileSession():SendRPC("GetVehicleData", { handsOffSteering = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { handsOffSteering = true })
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, 123, "SUCCESS", {}) -- invalid method
  end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", common.updatedPreloadedPTFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)

common.Title("Test")
common.Step("RPC GetVehicleData, HMI with invalid response", getVDHMIInvalidResponse)

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
