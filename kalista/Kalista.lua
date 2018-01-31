IncludeFile("Lib\\TOIR_SDK.lua")

Kalista = class()

function OnLoad()
	if GetChampName(GetMyChamp()) == "Kalista" then
		Kalista:__init()
	end
end

function Kalista:__init()
	vpred = VPrediction(true)
	self.Q = Spell(_Q, 1200)
	self.W = Spell(_W, 5000)
	self.E = Spell(_E, 1000)
	self.R = Spell(_R, 1400)
	
	self.Q:SetSkillShot(0.25, 1750, 300, false)
	self.W:SetActive()
	self.E:SetActive()
	self.R:SetActive()
	
	Callback.Add("Tick", function(...) self:OnTick(...) end)
	Callback.Add("Draw", function(...) self:OnDraw(...) end)
	Callback.Add("DrawMenu", function(...) self:OnDrawMenu(...) end)
	
	self:KalistaMenu()
end

function Kalista:KalistaMenu()
	self.menu = "Z-Kalista"
	---Draw
	self.draw_Q = self:MenuBool("Draw Q Range", true)
	self.draw_E = self:MenuBool("Draw E Range", true)
	---Harass
	self.harass_Q = self:MenuBool("Use Q in Harass", true)
	self.harass_E = self:MenuBool("Use E in Harass", true)
	self.harass_mana = self:MenuSliderInt("Harass  Mana % >", 60)
	---Clear
	self.clear_Q = self:MenuBool("Use Q in Harass", true)
	self.clear_E = self:MenuBool("Use E in Harass", true)
	self.clear_mana = self:MenuSliderInt("Harass  Mana % >", 60)
	---Combo
	self.combo_Q = self:MenuBool("Use Q in Combo", true)
	self.combo_E = self:MenuBool("Use E in Combo", true)
	---misc
	self.auto_save_HP = self:MenuSliderInt("if Ally HP % <", 15)
	self.auto_Save = self:MenuBool("Auto Save Ally", true)
	---key
	self.Combo = self:MenuKeyBinding("Combo", 32)
	self.Harass = self:MenuKeyBinding("Harass", 67)
	self.Last_Hit = self:MenuKeyBinding("Last Hit", 88)
	self.Lane_Clear = self:MenuKeyBinding("Lane Clear", 86)
	---
end

function Kalista:OnDrawMenu()
	if Menu_Begin(self.menu) then
		if Menu_Begin("Combo Setting") then
			self.combo_Q = Menu_Bool("Use Q in Combo", self.combo_Q, self.menu)
			self.combo_E = Menu_Bool("Use E in Combo", self.combo_E, self.menu)
			Menu_End()
		end
		if Menu_Begin("Harass Setting") then
			self.harass_Q = Menu_Bool("Use Q in Harass", self.harass_Q, self.menu)
			self.harass_E = Menu_Bool("Use E in Harass", self.harass_E, self.menu)
			self.harass_mana = Menu_SliderInt("Harass  Mana % >", self.harass_mana, 1, 100, self.menu)
			Menu_End()
		end
		if Menu_Begin("Clear Setting") then
			self.clear_Q = Menu_Bool("Use Q in clear", self.clear_Q, self.menu)
			self.clear_E = Menu_Bool("Use E in clear", self.clear_E, self.menu)
			self.clear_mana = Menu_SliderInt("clear  Mana % >", self.clear_mana, 1, 100, self.menu)
			Menu_End()
		end
		if Menu_Begin("R Setting") then
			self.auto_Save = Menu_Bool("Auto Save Ally", self.auto_Save, self.menu)
			Menu_End()
		end
		if Menu_Begin("Key Mode") then
			self.Combo = Menu_KeyBinding("Combo", self.Combo, self.menu)
			self.Harass = Menu_KeyBinding("Harass", self.Harass, self.menu)
			self.Lane_Clear = Menu_KeyBinding("Lane Clear", self.Lane_Clear, self.menu)
			self.Last_Hit = Menu_KeyBinding("Last Hit", self.Last_Hit, self.menu)
			Menu_End()
		end
		Menu_End()
	end
end

function Kalista:OnTick()
	if IsDead(myHero.Addr) or IsTyping() or IsDodging() then return end
	SetLuaCombo(true)
	
	if GetKeyPress(self.Combo) > 0 then
		self:KalistaCombo()
    end
	if GetKeyPress(self.Lane_Clear) >0 then
		self:clearLogic()
	end
	if GetKeyPress(self.Harass) > 0 then
		if myHero.MP / myHero.MaxMP * 100 > self.clear_mana 
		and self.harass_Q
		then
			self:KalistaCombo()
		end
	end
	self:AutoR()
	
end
---获取附近被标记的小兵
function Kalista:EnemyMinionsTbl()
    GetAllUnitAroundAnObject(myHero.Addr, 1200)
    local result = {}
    for i, obj in pairs(pUnit) do
        if obj ~= 0  then
            local minions = GetUnit(obj)
			if GetBuffByName(minions.Addr, "kalistaexpungemarker") ~= 0 then
				if IsEnemy(minions.Addr) 
					and not IsDead(minions.Addr) 
					and not IsInFog(minions.Addr) 
					and (GetType(minions.Addr) == 1 
					or GetType(minions.Addr) == 2) then
					table.insert(result, minions.Addr)
				end
			end
        end
    end
    return result
end

function Kalista:canKillMinion()
	for i, minions in ipairs(self:EnemyMinionsTbl()) do
		local minion = GetUnit(minions)
		if self:canKill(minion) then
			return true
		end
	end
	return false
end

function Kalista:canKill(unit)
	local hpPred = GetHealthPred(unit.Addr, 0.25, 0.07)
	if hpPred > 0 and hpPred < GetDamage("E", unit) then
		return true
	end
	return false
end

function Kalista:KalistaCombo()
	local TargetQ = GetTargetSelector(self.Q.range)
	if TargetQ ~= nil and TargetQ ~= 0 and self.combo_Q and CanCast(_Q) then
		target = GetAIHero(TargetQ)
		local CastPosition, HitChance, Position = vpred:GetLineCastPosition(target,
		self.Q.delay, 
		self.Q.width, 
		self.Q.range, 
		self.Q.speed, 
		myHero, 
		false)
		if HitChance >= 2 then
			CastSpellToPos(CastPosition.x, CastPosition.z, _Q)
		end
	end
	if self.combo_E and CanCast(_E) then
		for i,hero in pairs(GetEnemyHeroes()) do
			if hero~= 0 
			and IsValidTarget(hero, self.E.range) 
			and GetBuffByName(hero, "kalistaexpungemarker") ~= 0 then
				target = GetAIHero(hero)
				if self:canKill(target) and CanCast(_E) then
					CastSpellTarget(myHero.Addr, _E)
				end
			end
		end
	end
end

function Kalista:clearLogic()
	if CanCast(_Q) 
	and myHero.MP / myHero.MaxMP * 100 > self.clear_mana 
	and self.clear_Q 
	then
		if (GetObjName(GetTargetOrb()) ~= "PlantSatchel" and GetObjName(GetTargetOrb()) ~= "PlantHealth" and GetObjName(GetTargetOrb()) ~= "PlantVision") then
			target = GetUnit(GetTargetOrb())
	    	local CastPosition, HitChance, Position = vpred:GetLineCastPosition(target, self.Q.delay, self.Q.width, self.Q.range, self.Q.speed, myHero, false)
			CastSpellToPos(CastPosition.x, CastPosition.z, _Q)
		end
	end
end

function Kalista:AutoR()
	--kalistacoopstrikeally
	if self.auto_Save then
		for i,hero in pairs(GetAllyHeroes()) do
			if GetBuffByName(hero, "kalistaexpungemarker")~= 0
			and IsValidTarget(hero, self.R.range)
			then
				local target = GetAIHero(hero)
				if target.HP / target.MaxHP * 100 <= self.auto_save_HP then
					CastSpellTarget(myHero.Addr, _R)
				end
			end
		end
	end
end

function Kalista:OnDraw()
	if self.draw_Q then
		DrawCircleGame(myHero.x , myHero.y, myHero.z, self.Q.range, Lua_ARGB(255,255,0,0))
	end
	
	if self.draw_E then
		DrawCircleGame(myHero.x , myHero.y, myHero.z, self.Q.range, Lua_ARGB(255,255,0,0))
	end
end


function Kalista:MenuBool(stringKey, bool)
	return ReadIniBoolean(self.menu, stringKey, bool)
end

function Kalista:MenuSliderInt(stringKey, valueDefault)
	return ReadIniInteger(self.menu, stringKey, valueDefault)
end

function Kalista:MenuKeyBinding(stringKey, valueDefault)
	return ReadIniInteger(self.menu, stringKey, valueDefault)
end