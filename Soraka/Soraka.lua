IncludeFile("Lib\\TOIR_SDK.lua")



Soraka = class()



function OnLoad()
	if GetChampName(GetMyChamp()) == "Soraka" then
		Soraka:__init()
	end
end

function Soraka:__init()

	self.listSpellInterrup =
	{
	["KatarinaR"] = true,
	["AlZaharNetherGrasp"] = true,
	["TwistedFateR"] = true,
	["VelkozR"] = true,
	["InfiniteDuress"] = true,
	["JhinR"] = true,
	["CaitlynAceintheHole"] = true,
	["UrgotSwap2"] = true,
	["LucianR"] = true,
	["GalioIdolOfDurand"] = true,
	["MissFortuneBulletTime"] = true,
	["XerathLocusPulse"] = true,
	["VarusQ"] = true,
	["Crowstorm"] = true
	}
	vpred = VPrediction(true)
	self.Q = Spell(_Q, 800)
	self.W = Spell(_W, 550)
	self.E = Spell(_E, 550)
	self.R = Spell(_R, 3000)
	
	self.Q:SetSkillShot(0.5, 1750, 300, false)
	self.W:SetTargetted()
	self.E:SetSkillShot(0.25, 1750, 300, false)
	self.R:SetActive()
	Callback.Add("Tick", function(...) self:OnTick(...) end)
	Callback.Add("Draw", function(...) self:OnDraw(...) end)
	Callback.Add("DrawMenu", function(...) self:OnDrawMenu(...) end)
	Callback.Add("ProcessSpell", function(...) self:OnProcessSpell(...) end)
	self:MenuValueDefault()
end

function Soraka:MenuValueDefault()
	self.menu = "Z-Soraka"
	---Draw
	self.draw_Q = self:MenuBool("Draw Q Range", true)
	self.draw_W = self:MenuBool("Draw W Range", true)
	self.draw_E = self:MenuBool("Draw E Range", true)
	---Harass
	self.harass_Q = self:MenuBool("Use Q in Harass", true)
	self.harass_E = self:MenuBool("Use E in Harass", true)
	self.harass_mana = self:MenuSliderInt("Harass  Mana % >", 60)
	---Combo
	self.combo_Q = self:MenuBool("Use Q in Combo", true)
	self.combo_E = self:MenuBool("Use E in Combo", true)
	---heal
	self.heal_W = self:MenuSliderInt("Ally HP < % Use W", 80)
	self.heal_R = self:MenuBool("Use R", true)
	---key
	self.Combo = self:MenuKeyBinding("Combo", 32)
	self.Harass = self:MenuKeyBinding("Harass", 67)
	self.Last_Hit = self:MenuKeyBinding("Last Hit", 88)
end

function Soraka:OnDrawMenu()
	if Menu_Begin(self.menu) then
		if Menu_Begin("Draw Spell") then
			self.draw_Q = Menu_Bool("Draw Q Range", self.draw_Q, self.menu)
			self.draw_W = Menu_Bool("Draw W Range", self.draw_W, self.menu)
			self.draw_E = Menu_Bool("Draw E Range", self.draw_E, self.menu)
			Menu_End()
		end
		if Menu_Begin("Harass Setting") then
			self.harass_Q = Menu_Bool("Use Q in Harass", self.harass_Q, self.menu)
			self.harass_E = Menu_Bool("Use E in Harass", self.harass_E, self.menu)
			self.harass_mana = Menu_SliderInt("Harass  Mana % >", self.harass_mana, 1, 100, self.menu)
			Menu_End()
		end 
		if Menu_Begin("Heal Setting") then
			self.heal_W = Menu_SliderInt("Ally HP < % Use W", self.heal_W, 1, 100, self.menu)
			self.heal_R = Menu_Bool("Use R", self.heal_R, self.menu)
			Menu_End()
		end
		if Menu_Begin("Combo Setting") then
			self.combo_Q = Menu_Bool("Use Q in Combo", self.combo_Q, self.menu)
			self.combo_E = Menu_Bool("Use E in Combo", self.combo_E, self.menu)
			Menu_End()
		end
		if Menu_Begin("Key Mode") then
			self.Combo = Menu_KeyBinding("Combo", self.Combo, self.menu)
			self.Harass = Menu_KeyBinding("Harass", self.Harass, self.menu)
			self.Last_Hit = Menu_KeyBinding("Last Hit", self.Last_Hit, self.menu)
			Menu_End()
		end
		Menu_End()
	end
end

function Soraka:OnTick()
	if myHero.IsDead or IsTyping() or myHero.IsRecall or IsDodging() then return end
	SetLuaCombo(true)
	SetLuaHarass(true)
	
	
	
	if GetKeyPress(self.Combo) > 0 then
		self:SorakaCombo()
    end
	
	if GetKeyPress(self.Harass) > 0 then
		self:harass()
	end
	
	if self.heal_R then
		self:logicR()
	end
	
	self:logicW()
end

function Soraka:OnDraw()
	
end


function Soraka:SorakaCombo()
	self:logicQ()
	self:logicE()
end
---Q逻辑
function Soraka:logicQ()
	local TargetQ = GetTargetSelector(self.Q.range)
	if TargetQ ~= nil and TargetQ ~= 0 and self.combo_Q and CanCast(_Q) then
		target = GetAIHero(TargetQ)
		local CastPosition, HitChance, Position = vpred:GetLineCastPosition(target, self.Q.delay, self.Q.width, self.Q.range, self.Q.speed, myHero, false)
		if HitChance >= 2 then
			CastSpellToPos(CastPosition.x, CastPosition.z, _Q)
		end
	end
end
---W逻辑
function Soraka:logicW()
	--获取所有己方英雄
	for i, heros in ipairs(GetAllyHeroes()) do
		if heros ~= nil then
			local target = GetAIHero(heros)
			if target.HP / target.MaxHP * 100 <= self.heal_W  then
				if IsValidTarget(target, self.W.range) and CanCast(_W) then
					CastSpellTarget(target.Addr,_W)
				end
			end
		end
	end
end
---E逻辑
function Soraka:logicE()
	local TargetE = GetTargetSelector(self.E.range)
	if TargetE ~= nil and TargetE ~= 0 and self.combo_E and CanCast(_E) then
		target = GetAIHero(TargetE)
		local CastPosition, HitChance, Position = vpred:GetLineCastPosition(target, self.E.delay, self.E.width, self.E.range, self.E.speed, myHero, false)
		if HitChance >= 2 then
			CastSpellToPos(CastPosition.x, CastPosition.z, _E)
		end
	end
end

function Soraka:logicR()
	--获取所有己方英雄
	for i, heros in ipairs(GetAllyHeroes()) do
		if heros ~= nil then
			local target = GetAIHero(heros)
			if target.HP / target.MaxHP * 100 <= 15 then
				if CanCast(_R) then
					CastSpellTarget(myHero.Addr, _R)
				end
			end
		end
	end
end

function Soraka:harass()
	if myHero.MP / myHero.MaxMP * 100 > self.harass_mana  then
		self:SorakaCombo()
	end
end

function Soraka:OnProcessSpell(unit, spell)
	if unit.IsEnemy and self.listSpellInterrup[spell.Name] and IsValidTarget(unit, self.E.range) then
		local CastPosition, HitChance, Position = vpred:GetLineCastPosition(unit, self.E.delay, self.E.width, self.E.range, self.E.speed, myHero, false)
		if HitChance >= 2 then
			CastSpellToPos(CastPosition.x, CastPosition.z, _E)
		end
	end
end

function Soraka:MenuBool(stringKey, bool)
	return ReadIniBoolean(self.menu, stringKey, bool)
end

function Soraka:MenuSliderInt(stringKey, valueDefault)
	return ReadIniInteger(self.menu, stringKey, valueDefault)
end

function Soraka:MenuKeyBinding(stringKey, valueDefault)
	return ReadIniInteger(self.menu, stringKey, valueDefault)
end

