-- ==========================================
-- รายชื่อแมพและลิงก์สคริปต์ (สามารถมาเพิ่มทีหลังได้ง่ายๆ ตรงนี้)
-- ==========================================
local SupportedMaps = {
    [14419907512] = "https://raw.githubusercontent.com/jn5ncjzj7j-byte/Scripts/refs/heads/main/main/ZM.lua",
    [4655652068]  = "https://raw.githubusercontent.com/jn5ncjzj7j-byte/Scripts/refs/heads/main/main/NT.lua",
    [16389395869] = "https://raw.githubusercontent.com/xxqLgnd/Utilities/main/DustyTrip",
    [537413528] = "https://raw.githubusercontent.com/jn5ncjzj7j-byte/Scripts/refs/heads/main/main/babft.lua",
}

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local currentPlaceId = game.PlaceId
local targetScriptUrl = SupportedMaps[currentPlaceId]

if targetScriptUrl then
    loadstring(game:HttpGet(targetScriptUrl, true))()
else
    error("Game PlaceId (" .. currentPlaceId .. ") is not supported in Map Manager.")
end
