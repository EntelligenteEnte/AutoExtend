AutoExtend = LibStub("AceAddon-3.0"):NewAddon("AutoExtend", "AceEvent-3.0", "AceHook-3.0")

local defaults = {
    char = {
		extensions={},
		nextExtension=0
	}
}

function AutoExtend:OnInitialize()
	if IsAddOnLoaded("IDShare") then
		print("AutoExtend was disabled because IDShare is loaded.")
		DisableAddOn("AutoExtend", false)
		return
	end

	AutoExtend.db = LibStub("AceDB-3.0"):New("AutoExtendDB",defaults)
end

function AutoExtend:OnEnable()
	if IsAddOnLoaded("IDShare") then return end

	AutoExtend:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function AutoExtend:OnDisable()

end

local function initLockouts(number, count, sucesses)
	local numSavedInstances=GetNumSavedInstances()
	
	if count==10 and numSavedInstances==0 then
		return
	elseif count==60 then
		return
	end

	if numSavedInstances>0 then
		if numSavedInstances==number then
			if successes==2 then
				extendLockouts()
				return
			else
				successes=successes+1
			end
		else
			successes=0
		end
	end
	
	C_Timer.After(1, function() initLockouts(numSavedInstances, count+1, successes) end)
end

function AutoExtend:PLAYER_ENTERING_WORLD(_,isInitialLogin,isReloadingUi)
	if not isInitialLogin and not isReloadingUi then return end
	initLockouts(0,0,0)
end

function extendLockouts()
	local doExtend=GetServerTime()>AutoExtend.db.char.nextExtension
	local extensions=doExtend and AutoExtend.db.char.extensions or {}

	for i=1, GetNumSavedInstances() do
		local _,_,_,difficultyID,_,isExtended,_,_,_,_,_,_,_,id=GetSavedInstanceInfo(i)
		repeat
			if not id then break end

			if isExtended then
				if not extensions[id] then
					extensions[id]={}
				end
				extensions[id][difficultyID]=true
			elseif doExtend and extensions[id] and extensions[id][difficultyID] then
				SetSavedInstanceExtend(i,true)
			end
		until true
	end

	if doExtend then
		AutoExtend.db.char.nextExtension=GetServerTime()+C_DateAndTime.GetSecondsUntilWeeklyReset()
	end

	AutoExtend.db.char.extensions=extensions

	AutoExtend:SecureHook("SetSavedInstanceExtend")	
end

function AutoExtend:SetSavedInstanceExtend(index, extend)
	local _,_,_,difficultyID,_,isExtended,_,_,_,_,_,_,_,id=GetSavedInstanceInfo(index)
	if not AutoExtend.db.char.extensions[id] then
		AutoExtend.db.char.extensions[id]={}
	end
	AutoExtend.db.char.extensions[id][difficultyID]=isExtended
end