-- ==========================================
-- รายชื่อแมพและลิงก์สคริปต์ (สามารถมาเพิ่มทีหลังได้ง่ายๆ ตรงนี้)
-- ==========================================
local SupportedMaps = {
    [14419907512] = "https://raw.githubusercontent.com/jn5ncjzj7j-byte/Scripts/refs/heads/main/main/ZM.lua", -- ZM
    [4655652068]  = "https://raw.githubusercontent.com/jn5ncjzj7j-byte/Scripts/refs/heads/main/main/NT.lua", -- NT
    [16389395869] = "https://raw.githubusercontent.com/xxqLgnd/Utilities/main/DustyTrip", -- Dusty Trip (ADT)
    -- วิธีเพิ่มแมพใหม่ในอนาคต ให้พิมพ์เพิ่มในรูปแบบนี้:
    -- [เลข PlaceId ของแมพ] = "ลิงก์ Raw สคริปต์ของคุณ",
}

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local currentPlaceId = game.PlaceId
local targetScriptUrl = SupportedMaps[currentPlaceId]

if targetScriptUrl then
    -- ถ้ารองรับแมพนี้ ให้โหลดสคริปต์ของแมพนั้นทันที
    loadstring(game:HttpGet(targetScriptUrl, true))()
else
    -- ถ้าไม่รองรับ ให้แจ้งเตือน Error เพื่อให้สคริปต์ตัวบนรู้ว่าเกมนี้ไม่มีในระบบ
    error("Game PlaceId (" .. currentPlaceId .. ") is not supported in Map Manager.")
end
