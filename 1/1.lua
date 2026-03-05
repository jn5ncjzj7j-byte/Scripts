-- // Optimized Professional Loader
-- // Merged with your GitHub Paths

local cloneref = (cloneref or clonereference or function(instance)
    return instance
end)

local Players = cloneref(game:GetService("Players"))
local VirtualUser = cloneref(game:GetService("VirtualUser"))
local LPlayer = Players.LocalPlayer

-- Wait for game to load
repeat task.wait() until game:IsLoaded() and LPlayer

-- Anti-AFK Logic
LPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

local Loader = {}

-- Map your Games here
-- ZM = 14419907512, NT = 4655652068, BL = 14890802310
Loader.Files = {
    ["ZM Game"] = {
        Id = 14419907512,
        File = "main/ZM.lua"
    },
    ["NT Game"] = {
        Id = 4655652068,
        File = "main/NT.lua"
    },
    ["BL Game"] = {
        Id = 14890802310,
        File = "main/BL.lua"
    }
}

function Loader:Execute()
    local currentId = game.PlaceId
    
    for GameName, Data in pairs(self.Files) do
        -- Check if current game matches ID
        if Data.Id == currentId then
            local Url = "https://raw.githubusercontent.com/jn5ncjzj7j-byte/Scripts/main/" .. Data.File
            
            -- task.spawn prevents the "Execution Timeout" freeze
            task.spawn(function()
                local Success, ScriptContent = pcall(function()
                    return game:HttpGet(Url)
                end)

                if Success then
                    local func, err = loadstring(ScriptContent)
                    if func then
                        print("✅ Successfully Loaded:", GameName)
                        func() -- Execute the script
                    else
                        warn("❌ Script Syntax Error:", err)
                    end
                else
                    warn("❌ Network Error: Could not reach GitHub")
                end
            end)
            return
        end
    end

    warn("UNSUPPORTED GAME 🤡 | ID: " .. currentId)
end

Loader:Execute()

return Loader
