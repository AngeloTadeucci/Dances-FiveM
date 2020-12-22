local currentIntensity = 1 -- 1 = low, 2 = medium, 3 = high
local currentDanceId = nil
local currentDance = nil
local dancing = false
local props = {}
local lastAnimation
local lastDict
local lastIntensity


TriggerEvent('chat:addSuggestion', '/dance', 'Dance!', {
	{
		name = "options",
		help = "Between 1 and 210 or boxing, trip, jumper, shuffle, karate, monkey"
	}
})

RegisterCommand("dance", function (source, args)
	if args[1] == "c" or args[1] == "cancel" then
		ClearPedTasks(PlayerPedId())
		dancing = false
		return
	end
	local input
	if type(args[1]) == "string" then
		if args[1] == "boxing" then
			input = 133
		elseif args[1] == "trip" then
			input = 134
		elseif args[1] == "jumper" then
			input = 135
		elseif args[1] == "shuffle" then
			input = 136
		elseif args[1] == "karate" then
			input = 137
		elseif args[1] == "monkey" then
			input = 138
		else
			return TriggerEvent('chat:addMessage', {
				color = { 255, 255, 255},
				multiline = true,
				args = {"There isn't a dance with this name."}
			})
		end
	else
		input = args[1] == nil and math.random(#Dances) or tonumber(args[1])
		if input > #Dances then
			return TriggerEvent('chat:addMessage', {
				color = { 255, 255, 255},
				multiline = true,
				args = {"There is only " .. #Dances .. " dances."}
			})
		end
	end
	currentDanceId = input
	currentDance = Dances[currentDanceId]
	dancing = true
end)

CreateThread(function ()
	local tempAnim
	local tempDict

	while true do
		if dancing then
			if IsControlJustPressed(0, 73) then -- X to clear task
				ClearPedTasks(PlayerPedId())
				DestroyAllProps()
				dancing = false
			end
			if IsControlJustPressed(0, 172) then -- up arrow more intensity
				if currentIntensity ~= 3 then
					currentIntensity = currentIntensity + 1
				end
			end
			if IsControlJustPressed(0, 173) then -- down arrow less intensity
				if currentIntensity ~= 1 then
					currentIntensity = currentIntensity - 1
				end
			end
			if IsControlJustPressed(0, 174) then -- left arrow previous dance
				currentDanceId = currentDanceId - 1
				if currentDanceId < 1 then
					currentDanceId = #Dances
				end
				currentDance = Dances[currentDanceId]
			end
			if IsControlJustPressed(0, 175) then -- right arrow next dance
				currentDanceId = currentDanceId + 1
				if currentDanceId > #Dances then
					currentDanceId = 1
				end
				currentDance = Dances[currentDanceId]
			end
			if currentDance.controlable then -- if dance can control up/down/left/right
				if IsControlPressed(0, 34) then -- A
					if IsControlPressed(0, 32) then -- A and W
						tempAnim = "left_up"
					elseif IsControlPressed(0, 33) then -- A and S
						tempAnim = "left_down"
					else
						tempAnim = "left"
					end
				elseif IsControlPressed(0, 35) then -- D
					if IsControlPressed(0, 32) then -- D and W
						tempAnim = "right_up"
					elseif IsControlPressed(0, 33) then -- D and S
						tempAnim = "right_down"
					else
						tempAnim = "right"
					end
				elseif IsControlPressed(0, 32) then -- W
					tempAnim = "center_up"
				elseif IsControlPressed(0, 33) then -- S
					tempAnim = "center_down"
				else -- No keys pressed
					tempAnim = "center"
				end
				if currentIntensity == 1 then
					tempAnim = currentDance.intensityLevels[currentIntensity] .. tempAnim
				elseif currentIntensity == 2 then
					tempAnim = currentDance.intensityLevels[currentIntensity] .. tempAnim
				else
					tempAnim = currentDance.intensityLevels[currentIntensity] .. tempAnim
				end
				tempDict = currentDance.dict[1]
			else
				if #currentDance.intensityLevels == 1 then
					tempAnim = currentDance.intensityLevels[1] .. currentDance.anim
					tempDict = currentDance.dict[1]
					currentIntensity = 3
				else
					tempAnim = currentDance.intensityLevels[currentIntensity] .. currentDance.anim
					tempDict = currentDance.dict[currentIntensity]
				end
			end
			if lastIntensity ~= currentIntensity or tempAnim ~= lastAnimation or tempDict ~= lastDict then
				DestroyAllProps()
				print(("Dance ID: %s, Intensity: %s"):format(currentDanceId, currentIntensity)) -- debug print
				LoadAnimationDict(tempDict)
				TaskPlayAnim(PlayerPedId(), tempDict, tempAnim, 1.0, 1.0, -1, 1, 0, 0, 0, 0)
				if currentDance.prop ~= nil then
					local propId = currentDance.prop.id
					local propBone = currentDance.prop.bone
					local offsetx, offsety, offsetz, rotx, roty, rotz = table.unpack(currentDance.prop.placement)
					AddPropToPlayer(propId, propBone, offsetx, offsety, offsetz, rotx, roty, rotz)
				end
				lastIntensity = currentIntensity
				lastAnimation = tempAnim
				lastDict = tempDict
			end
		end
		Wait(0)
	end
end)

function DestroyAllProps()
	for _,v in pairs(props) do
		DeleteEntity(v)
	end
end

function LoadPropDict(model)
	while not HasModelLoaded(GetHashKey(model)) do
		RequestModel(GetHashKey(model))
		Wait(10)
	end
end

function AddPropToPlayer(pProp, pBoneID, off1, off2, off3, rot1, rot2, rot3)
	local ped = PlayerPedId()
	local x,y,z = table.unpack(GetEntityCoords(ped))

	if not HasModelLoaded(pProp) then
		LoadPropDict(pProp)
	end

	prop = CreateObject(GetHashKey(pProp), x, y, z+0.2,  true,  true, true)
	AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, pBoneID), off1, off2, off3, rot1, rot2, rot3, true, true, false, true, 1, true)
	table.insert(props, prop)
	SetModelAsNoLongerNeeded(pProp)
end

function LoadAnimationDict(dict)
	if not HasAnimDictLoaded(dict) then
		RequestAnimDict(dict)
		while not HasAnimDictLoaded(dict) do
			Wait(10)
		end
	end
end