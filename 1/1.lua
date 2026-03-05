local cloneref = (cloneref or clonereference or function(instance)
    return instance
end)

local Players = cloneref(game:GetService("Players"))
local VirtualUser = cloneref(game:GetService("VirtualUser"))
local LPlayer = Players.LocalPlayer

repeat task.wait() until game:IsLoaded() and LPlayer

LPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

local Loader = {}

Loader.Files = {
    ["Bizzare Lineage"] = {
        File = "main/BL.lua",
        CreatorId = 5271390838
    },
    ["Zombie Game"] = {
        File = "main/Zm.lua"
        CreaterId = 5386185136
    },
}

function Loader:LoadByCreatorId(CreatorId)
    for GameName, Data in pairs(self.Files) do
        if Data.CreatorId == CreatorId then
            
            local Url = "https://github.com/jn5ncjzj7j-byte/Scripts/main" .. Data.File
            
            local Success, Result = pcall(function()
                return loadstring(game:HttpGet(Url))()
            end)

            if Success then
                print("✅ Loaded:", GameName)
            else
                warn("❌ Load failed:", Result)
            end

            return
        end
    end

    warn("UNSUPPORTED GAME 🤡")
end

Loader:LoadByCreatorId(game.CreatorId)

return Loader
