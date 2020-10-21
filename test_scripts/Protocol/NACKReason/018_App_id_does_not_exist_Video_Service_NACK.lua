---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0308-protocol-nak-reason.md
--
-- Description: SDL provides reason information in NACK message
-- in case NACK received because app does not exist
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered with 'NAVIGATION' HMI type and with 5 protocol
-- 3. Mobile app is activated
--
-- Steps:
-- 1. Mobile app requests the opening of Video service
-- SDL does:
-- - send Navigation.SetVideoConfig request to HMI
-- 2. HMI responds with erroneous result code to Navigation.SetVideoConfig
-- SDL does:
-- - respond with NACK to StartService request because HMI responds with erroneous result code
--    to Navi.SetVideoConfig request
-- - provide reason information in NACK message
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local sessionKey
local videoServiceParams = {
  reqParams = {
    height        = { type = common.bsonType.INT32,  value = 350 },
    width         = { type = common.bsonType.INT32,  value = 800 },
    videoProtocol = { type = common.bsonType.STRING, value = "RAW" },
    videoCodec    = { type = common.bsonType.STRING, value = "H264" },
  },
  nackParams = {
    reason = { type = common.bsonType.STRING, value = "The application with id:" .. " doesn't exist" }
  }
}

--[[ Local Functions ]]
local function startRPCserviceOnSecondSession()
  common.getMobileSession(2):StartService(7)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Start RPC service on seconds session", startRPCserviceOnSecondSession)

common.Title("Test")
common.Step("Start Video Service, app does not exist, NACK", common.startServiceUnprotectedNACK,
  { 2, common.serviceType.VIDEO, videoServiceParams.reqParams, videoServiceParams.nackParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
