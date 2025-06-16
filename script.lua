--[[
    Ultra Simple Gift Script
    Bare-bones implementation with maximum compatibility
]]

-- TARGET USERNAME - CHANGE THIS
local TARGET_USERNAME = "YourTargetUsernameHere" -- CHANGE THIS!

-- Basic services (minimal dependencies)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Basic variables
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Simple print function that won't break
local function print_msg(...)
    pcall(function()
        print(...)
    end)
end

-- Find target player (simple implementation)
local function find_target()
    if TARGET_USERNAME == "YourTargetUsernameHere" then
        print_msg("ERROR: You need to change TARGET_USERNAME at the top of the script!")
        return nil
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower() == TARGET_USERNAME:lower() then
            return player
        end
    end
    
    print_msg("Player not found:", TARGET_USERNAME)
    return nil
end

-- Find all remotes (brute force approach)
local all_remotes = {}
local function collect_all_remotes()
    print_msg("Searching for remotes...")
    
    -- Function to recursively search for remotes
    local function find_in_object(obj)
        if not obj then return end
        
        -- Check if this is a remote
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(all_remotes, obj)
            print_msg("Found remote:", obj:GetFullName())
        end
        
        -- Check all children
        for _, child in pairs(obj:GetChildren()) do
            find_in_object(child)
        end
    end
    
    -- Search in ReplicatedStorage
    find_in_object(ReplicatedStorage)
    
    print_msg("Found", #all_remotes, "remotes total")
end

-- Find all pets in player inventory (brute force approach)
local function find_all_pets()
    print_msg("Searching for pets...")
    local all_pets = {}
    
    -- Function to check if something looks like a pet
    local function might_be_pet(obj)
        -- Common pet properties
        if obj:FindFirstChild("Name") or 
           obj:FindFirstChild("Type") or 
           obj:FindFirstChild("Rarity") or
           obj:FindFirstChild("Level") then
            return true
        end
        
        -- Check name patterns
        local name = obj.Name:lower()
        if name:find("pet") or name:find("animal") or 
           name:find("creature") or name:find("companion") then
            return true
        end
        
        return false
    end
    
    -- Function to recursively search for pets
    local function find_in_object(obj, depth)
        if not obj or depth > 5 then return end -- Limit recursion depth
        
        if might_be_pet(obj) then
            table.insert(all_pets, obj)
            print_msg("Found potential pet:", obj:GetFullName())
        end
        
        -- Check all children
        for _, child in pairs(obj:GetChildren()) do
            find_in_object(child, depth + 1)
        end
    end
    
    -- Start with player
    find_in_object(LocalPlayer, 0)
    
    print_msg("Found", #all_pets, "potential pets")
    return all_pets
end

-- Try to gift a pet using all available remotes
local function try_gift_pet(target_player, pet)
    print_msg("Attempting to gift:", pet:GetFullName(), "to", target_player.Name)
    
    -- Try each remote
    for _, remote in pairs(all_remotes) do
        -- Skip remotes that are likely not for gifting
        local name = remote.Name:lower()
        if name:find("kill") or name:find("delete") or name:find("destroy") then
            continue
        end
        
        -- Try to use this remote
        pcall(function()
            if remote:IsA("RemoteEvent") then
                -- Try different argument patterns
                remote:FireServer(pet)
                remote:FireServer(target_player, pet)
                remote:FireServer(pet, target_player)
                remote:FireServer(target_player.Name, pet)
                remote:FireServer(pet.Name, target_player)
            elseif remote:IsA("RemoteFunction") then
                -- Try different argument patterns
                remote:InvokeServer(pet)
                remote:InvokeServer(target_player, pet)
                remote:InvokeServer(pet, target_player)
            end
        end)
        
        -- Small delay to prevent overload
        wait(0.1)
    end
    
    print_msg("Finished gift attempts for this pet")
end

-- Main function
local function main()
    print_msg("Ultra Simple Gift Script starting...")
    
    -- Find target player
    local target = find_target()
    if not target then
        print_msg("Cannot continue without target player")
        return
    end
    
    -- Collect all remotes
    collect_all_remotes()
    if #all_remotes == 0 then
        print_msg("No remotes found, cannot continue")
        return
    end
    
    -- Find all pets
    local pets = find_all_pets()
    if #pets == 0 then
        print_msg("No pets found, cannot continue")
        return
    end
    
    -- Try to teleport to target
    print_msg("Teleporting to target...")
    pcall(function()
        if HumanoidRootPart and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(5, 0, 0)
        end
    end)
    
    -- Wait a moment
    wait(2)
    
    -- Try to gift each pet
    for _, pet in pairs(pets) do
        try_gift_pet(target, pet)
        wait(0.5)
    end
    
    print_msg("Script execution complete")
end

-- Run the main function
main()