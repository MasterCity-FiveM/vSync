ESX                = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
------------------ change this -------------------

-- Set this to false if you don't want the weather to change automatically every 10 minutes.
DynamicWeather = true

--------------------------------------------------
debugprint = false -- don't touch this unless you know what you're doing or you're being asked by Vespura to turn this on.
--------------------------------------------------

-------------------- DON'T CHANGE THIS --------------------
AvailableWeatherTypes = {
    'EXTRASUNNY', 
    'CLEAR', 
    'NEUTRAL', 
    'SMOG', 
    'FOGGY', 
    'OVERCAST', 
    'CLOUDS', 
    'CLEARING', 
    'RAIN', 
    'THUNDER', 
    'SNOW', 
    'BLIZZARD', 
    'SNOWLIGHT', 
    'XMAS', 
    'HALLOWEEN',
}
CurrentWeather = "EXTRASUNNY"
local baseTime = 0
local timeOffset = 0
local freezeTime = false
local blackout = false
local newWeatherTimer = 10

RegisterServerEvent('vSync:requestSync')
AddEventHandler('vSync:requestSync', function()
    TriggerClientEvent('vSync:updateWeather', -1, CurrentWeather, blackout)
    TriggerClientEvent('vSync:updateTime', -1, baseTime, timeOffset, freezeTime)
end)

function ShiftToMinute(minute)
    timeOffset = timeOffset - ( ( (baseTime+timeOffset) % 60 ) - minute )
end

function ShiftToHour(hour)
    timeOffset = timeOffset - ( ( ((baseTime+timeOffset)/60) % 24 ) - hour ) * 60
end

ESX.RunCustomFunction("AddCommand", "time", 1, function(xPlayer, args)
	if tonumber(args.hour) ~= nil and tonumber(args.min) ~= nil then
		local argh = tonumber(args.hour)
		local argm = tonumber(args.min)
		if argh < 24 then
			ShiftToHour(argh)
		else
			ShiftToHour(0)
		end
		if argm < 60 then
			ShiftToMinute(argm)
		else
			ShiftToMinute(0)
		end
		local newtime = math.floor(((baseTime+timeOffset)/60)%24) .. ":"
		local minute = math.floor((baseTime+timeOffset)%60)
		if minute < 10 then
			newtime = newtime .. "0" .. minute
		else
			newtime = newtime .. minute
		end
		TriggerClientEvent('vSync:notify', xPlayer.source, 'Time was changed to: ~y~' .. newtime .. "~s~!")
		TriggerEvent('vSync:requestSync')
	else
		TriggerClientEvent('chatMessage', xPlayer.source, '', {255,255,255}, '^8Error: ^1Invalid syntax. Use ^0/time <hour> <minute> ^1instead!')
	end
end, {
	{name = 'hour', type = 'number'},
	{name = 'min', type = 'number'}
}, '.time hour min', '.')

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local newBaseTime = os.time(os.date("!*t"))/2 + 360
        if freezeTime then
            timeOffset = timeOffset + baseTime - newBaseTime			
        end
        baseTime = newBaseTime
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        TriggerClientEvent('vSync:updateTime', -1, baseTime, timeOffset, freezeTime)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000)
        TriggerClientEvent('vSync:updateWeather', -1, CurrentWeather, blackout)
    end
end)

Citizen.CreateThread(function()
    while true do
        newWeatherTimer = newWeatherTimer - 1
        Citizen.Wait(60000)
        if newWeatherTimer == 0 then
            if DynamicWeather then
                NextWeatherStage()
            end
            newWeatherTimer = 30
        end
    end
end)

function NextWeatherStage()
    if CurrentWeather == "CLEAR" or CurrentWeather == "CLOUDS" or CurrentWeather == "EXTRASUNNY"  then
        local new = math.random(1,2)
        if new == 1 then
            CurrentWeather = "CLEARING"
        else
            CurrentWeather = "OVERCAST"
        end
    elseif CurrentWeather == "CLEARING" or CurrentWeather == "OVERCAST" then
        local new = math.random(1,6)
        if new == 1 then
            if CurrentWeather == "CLEARING" then CurrentWeather = "FOGGY" else CurrentWeather = "RAIN" end
        elseif new == 2 then
            CurrentWeather = "CLOUDS"
        elseif new == 3 then
            CurrentWeather = "CLEAR"
        elseif new == 4 then
            CurrentWeather = "EXTRASUNNY"
        elseif new == 5 then
            CurrentWeather = "SMOG"
        else
            CurrentWeather = "FOGGY"
        end
    elseif CurrentWeather == "THUNDER" or CurrentWeather == "RAIN" then
        CurrentWeather = "CLEARING"
    elseif CurrentWeather == "SMOG" or CurrentWeather == "FOGGY" then
        CurrentWeather = "CLEAR"
    end
    TriggerEvent("vSync:requestSync")
    if debugprint then
        print("[vSync] New random weather type has been generated: " .. CurrentWeather .. ".\n")
        print("[vSync] Resetting timer to 10 minutes.\n")
    end
end

AddEventHandler('vSync:setWeather', function(weather)
    for i,wtype in ipairs(AvailableWeatherTypes) do
		if wtype == string.upper(weather) then
			validWeatherType = true
		end
	end
	
	freezeTime = true
	DynamicWeather = true
	
	if validWeatherType then
		CurrentWeather = string.upper(weather)
		newWeatherTimer = 10
		TriggerEvent('vSync:requestSync')
	end
end)

AddEventHandler('vSync:setTime', function(hour, minutes)
    freezeTime = true
	DynamicWeather = true
	
	if tonumber(hour) ~= nil and tonumber(minutes) ~= nil then
		local argh = tonumber(hour)
		local argm = tonumber(minutes)
		if argh < 24 then
			ShiftToHour(argh)
		else
			ShiftToHour(0)
		end
		if argm < 60 then
			ShiftToMinute(argm)
		else
			ShiftToMinute(0)
		end
		local newtime = math.floor(((baseTime+timeOffset)/60)%24) .. ":"
		local minute = math.floor((baseTime+timeOffset)%60)
		if minute < 10 then
			newtime = newtime .. "0" .. minute
		else
			newtime = newtime .. minute
		end
		TriggerEvent('vSync:requestSync')
	end
end)