-- << SERVICES >>

local Lighting = game:GetService("Lighting")


-- << CONSTANTS >>

local DayInset = 6 -- Will loop between 5.7 and (24-5.7) in terms of time to preserve shadows.
local DayLength = 24-(DayInset*2) -- half the hours in our new "day"

local DayTimeLength = 15 -- Amount of time in seconds
local TickIncrement = DayLength/DayTimeLength

local LightingSerialised = { -- I am storing colors as vectors so they don't get clamped
	Day = {
		Ambient = Vector3.new(111, 94, 75); 
		Brightness = 1.5;
		ColorShift_Bottom = Vector3.new(111, 94, 75);
		ColorShift_Top = Vector3.new(255, 236, 198);
		EnvironmentDiffuseScale = 0.2;
		EnvironmentSpecularScale = 0.3;
		OutdoorAmbient = Vector3.new(180, 166, 166);
		ShadowSoftness = 0.1;
	};
	Night = {
		Ambient = Vector3.new(53, 99, 107);
		Brightness = 1;
		ColorShift_Bottom = Vector3.new(0, 76, 86);
		ColorShift_Top = Vector3.new(202, 215, 255);
		EnvironmentDiffuseScale = 0.5;
		EnvironmentSpecularScale = 0.2;
		OutdoorAmbient = Vector3.new(180, 166, 166);
		ShadowSoftness = 0.5;
	};
	Delta = {
		
	}
} 

local EffectSerialised = {
	ColorCorrection = {
		Day = {
			Brightness = 0.05;
			Contrast = 0.35;
			Saturation = 0.3;
			TintColor = Vector3.new(255,255,255);
		};
		Night = {
			Brightness = 0.05;
			Contrast = 0.25;
			Saturation = 0.2;
			TintColor = Vector3.new(196, 194, 255);
		};
		Delta = {
			
		}
	};
	SunRays = {
		Day = {
			Intensity = 0.11;
			Spread = 1;
		};
		Night = {
			Intensity = 0.01;
			Spread = 0.2;
		};
		Delta = {
			
		}
	};
	Atmosphere = {
		Day = {
			Density = 0.25;
			Offset = 0.5;
			Color = Vector3.new(254, 255, 253);
			Decay = Vector3.new(255,246,220);
			Glare = 0.5;
			Haze = 0.05;
		};
		Night = {
			Density = 0.395;
			Offset = 0;
			Color = Vector3.new(7, 64, 128);
			Decay = Vector3.new(0,0,0);
			Glare = 1.98;
			Haze = 1.98;
		};
		Delta = {
			
		}
	};
}

-- << GLOBALS >>

local FXFolder = script:WaitForChild("FX")
local dayFXFolder = FXFolder:WaitForChild("Day")
local dayFX = dayFXFolder:GetChildren()
local nightFXFolder = FXFolder:WaitForChild("Night")
local nightFX = nightFXFolder:GetChildren()

local effects = {
	ColorCorrection = "ColorCorrectionEffect";
	SunRays = "SunRaysEffect";
	Atmosphere = "Atmosphere";
}

-- << INITIALISATION FUNCTIONS >>

local function ConfigureDeltas()
	for key, value in pairs(LightingSerialised.Night) do
		LightingSerialised.Delta[key] = value - LightingSerialised.Day[key]
	end
	for _, item in pairs(EffectSerialised) do
		for key, value in pairs(item.Night) do
			item.Delta[key] = value - item.Day[key]
		end
	end
end

local function CreateEffects()
	for key, effectName in pairs(effects) do
		effects[key] = Instance.new(effectName, Lighting)
	end
end

-- << UTILITY FUNCTIONS >>

local function GetNewLightingValue(alpha, key)
	return LightingSerialised.Day[key] + (alpha*LightingSerialised.Delta[key]) 
end

local function GetNewEffectValue(effectName, alpha, key)
	return EffectSerialised[effectName].Day[key] + (alpha*EffectSerialised[effectName].Delta[key])
end

-- << LIGHTING FUNCTIONS >>

local function ApplyNewLighting(dayProgression)
	local alpha = (math.sin(dayProgression/(DayLength*2) * math.pi * 2) + 1)/2
	
	for property, _ in pairs(LightingSerialised.Day) do
		local newValue = GetNewLightingValue(alpha, property)
		if typeof(newValue) == "Vector3" then
			Lighting[property] = Color3.fromRGB(newValue.x, newValue.y, newValue.z)
		else
			Lighting[property] = newValue
		end
	end
	
	for effectName, effect in pairs(effects) do
		for property, _ in pairs(EffectSerialised[effectName].Day) do
			local newValue = GetNewEffectValue(effectName, alpha, property)
			if typeof(newValue) == "Vector3" then
				effect[property] = Color3.fromRGB(newValue.x, newValue.y, newValue.z)
			else
				effect[property] = newValue
			end
		end
	end
end

local function UpdateDayTime(currentTime, dt, isDay)
	currentTime = currentTime + (dt*TickIncrement)
	
	if currentTime < DayLength then
		if isDay then
			isDay = false
			for _, effect in pairs(nightFX) do
				effect.Parent = Lighting
			end
			for _, effect in pairs(dayFX) do
				effect.Parent = dayFXFolder
			end
		end
		
		Lighting.ClockTime = DayInset + currentTime
	elseif currentTime >= DayLength and currentTime < (DayLength * 2) then
		if not isDay then
			isDay = true
			for _, effect in pairs(dayFX) do
				effect.Parent = Lighting
			end
			for _, effect in pairs(nightFX) do
				effect.Parent = nightFXFolder
			end
		end
		
		Lighting.ClockTime = DayInset + (currentTime-DayLength)
	elseif currentTime >= DayLength * 2 then
		currentTime = 0
		isDay = true
	end
	
	ApplyNewLighting(currentTime)
	
	return currentTime, isDay
end

-- << MAIN LOOP >>

local function mainLoop()
	local ct = 0
	local id = true
	while wait(0.1) do
		ct, id = UpdateDayTime(ct, 0.1, id)
	end
end

-- << INITIALISATION >>

ConfigureDeltas()
CreateEffects()

-- << RETURNEE >>

return mainLoop
