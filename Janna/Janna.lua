IncludeFile("Lib\\TOIR_SDK.lua")
Janna = class()



function OnLoad()
	if GetChampName(GetMyChamp()) == "Janna" then
		Janna:__init()
	end
end

function Janna:__init()
	
	SetLuaCombo(true)
	SetLuaHarass(true)
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
	["Crowstorm"] = true,
	["XenZhaoSweep"] = true,
	["JaxLeapStrike"] = true,
	["BlindMonkQTwo"] = true
	}
	vpred = VPrediction(true)
	self.Q = Spell(_Q, 1700)
	self.W = Spell(_W, 600)
	self.E = Spell(_E, 800)
	self.R = Spell(_R, 875)
	
	self.isQactive = false
	self.qtime = 0
	self.lastQtime = 0
	
	self.Q:SetSkillShot(0.5, 1750, 120, false)
	self.W:SetTargetted()
	self.E:SetTargetted()
	self.R:SetActive()
	Callback.Add("Tick", function(...) self:OnTick(...) end)
	Callback.Add("Draw", function(...) self:OnDraw(...) end)
	Callback.Add("DrawMenu", function(...) self:OnDrawMenu(...) end)
	Callback.Add("ProcessSpell", function(...) self:OnProcessSpell(...) end)
	Callback.Add("UpdateBuff", function(...) self:OnUpdateBuff(...) end)
	Callback.Add("RemoveBuff", function(...) self:OnRemoveBuff(...) end)
	self:JannaMenu()
end

function Janna:JannaMenu()
	self.menu = "Z-Janna"
	---Draw
	self.draw_Q = self:MenuBool("Draw Q Range", true)
	self.draw_W = self:MenuBool("Draw W Range", true)
	self.draw_E = self:MenuBool("Draw E Range", true)
	self.draw_R = self:MenuBool("Draw R Range", true)
	---Harass
	self.harass_Q = self:MenuBool("Use Q in Harass", true)
	self.harass_W = self:MenuBool("Use W in Harass", true)
	self.harass_mana = self:MenuSliderInt("Harass  Mana % >", 60)
	---Combo
	self.combo_Q = self:MenuBool("Use Q in Combo", true)
	self.combo_W = self:MenuBool("Use E in Combo", true)
	---Misc Setting
	self.use_Q = self:MenuBool("Use Q to interrupt",true)
	self.use_E = self:MenuBool("Use E to Ally", true)
	self.use_R = self:MenuBool("Use R to Ally", true)
	self.use_R_HP = self:MenuSliderInt("if HP % < Use R", 30)
	---key
	self.Combo = self:MenuKeyBinding("Combo", 32)
	self.Harass = self:MenuKeyBinding("Harass", 67)
end

---Menu
function Janna:OnDrawMenu()
	if Menu_Begin(self.menu) then		
		if Menu_Begin("Draw Spell") then
			self.draw_Q = Menu_Bool("Draw Q Range", self.draw_Q, self.menu)
			self.draw_W = Menu_Bool("Draw W Range", self.draw_W, self.menu)
			self.draw_E = Menu_Bool("Draw E Range", self.draw_E, self.menu)
			self.draw_R = Menu_Bool("Draw R Range", self.draw_R, self.menu)
			Menu_End()
		end
		if Menu_Begin("Combo Setting") then
			self.combo_Q = Menu_Bool("Use Q in Combo", self.combo_Q, self.menu)
			self.combo_W = Menu_Bool("Use W in Combo", self.combo_W, self.menu)
			Menu_End()
		end
		if Menu_Begin("Harass Setting") then
			self.harass_Q = Menu_Bool("Use Q in Harass", self.harass_Q, self.menu)
			self.harass_W = Menu_Bool("Use W in Harass", self.harass_W, self.menu)
			self.harass_mana = Menu_SliderInt("Harass  Mana % >", 
			self.harass_mana, 1, 100, 
			self.menu)
			Menu_End()
		end
		if Menu_Begin("Misc Setting") then
			self.use_Q = Menu_Bool("Use Q to interrupt", self.use_Q, self.menu)
			self.use_E = Menu_Bool("Use E to Ally", self.use_E, self.menu)
			self.use_R = Menu_Bool("Use R to Ally", self.use_R, self.menu)
			self.use_R_HP = Menu_SliderInt("if HP % < Use R", self.use_R_HP,1, 100,self.menu)
			Menu_End()
		end
		if Menu_Begin("Key Mode") then
			self.Combo = Menu_KeyBinding("Combo", self.Combo, self.menu)
			self.Harass = Menu_KeyBinding("Harass", self.Harass, self.menu)
			Menu_End()
		end
	end
end



function Janna:OnDraw()
	if self.draw_Q and CanCast(_Q) then
		DrawCircleGame(myHero.x,myHero.y,myHero.z,self.Q.range,Lua_ARGB(255,255,0,0))
	end
	if self.draw_W and CanCast(_W) then
		DrawCircleGame(myHero.x,myHero.y,myHero.z,self.W.range,Lua_ARGB(255,0,255,0))
	end
	if self.draw_E and CanCast(_E) then
		DrawCircleGame(myHero.x,myHero.y,myHero.z,self.E.range,Lua_ARGB(255,0,0,255))
	end
	if self.draw_R and CanCast(_R) then
		DrawCircleGame(myHero.x,myHero.y,myHero.z,self.R.range,Lua_ARGB(255,0,255,255))
	end
end

function Janna:OnTick()
	if myHero.IsDead or IsTyping() or myHero.IsRecall or IsDodging() then return end
	if GetKeyPress(self.Combo) > 0 then
		if self.combo_Q then
			self:logicQ()
		end
		if self.combo_W then
			self:logicW()
		end
	end
	if GetKeyPress(self.Harass) > 0 then
		if myHero.MP / myHero.MaxMP * 100 > self.harass_mana  then
			if self.harass_Q then
				self:logicQ()
			end
			if self.harass_W then
				self:logicW()
			end
		end
	end
	self:logicR()
end


function Janna:OnProcessSpell(unit,spell)
	if unit.IsEnemy 
	and self.listSpellInterrup[spell.Name] 
	and CanCast(_Q) 
	and self.use_Q
	and IsValidTarget(unit, self.Q.range) 
	then
		local CastPosition, HitChance, Position = vpred:GetLineCastPosition(unit, 
		self.Q.delay, 
		self.Q.width, 
		self.Q.range, 
		self.Q.speed, 
		myHero, 
		false)
		if HitChance >= 2 then
			CastSpellToPos(CastPosition.x, CastPosition.z, _Q)
			CastSpellTarget(myHero.Addr,_Q)
		end
	end
	if unit.IsEnemy and unit.Type == 0 then
		for i, heros in ipairs(GetAllyHeroes()) do
		if heros ~= nil then
			local target = GetAIHero(heros)
			if target and target.Id == spell.TargetId then
				if IsValidTarget(target,self.E.range) 
				and CanCast(_E) 
				and self.use_E
				then
					CastSpellTarget(target.Addr,_E)
				end
			end
		end
	end
	end
end


function Janna:OnUpdateBuff(unit,buff)
	if unit.IsMe 
	and buff.Name == "HowlingGale"
	then
		self.isQactive = true
		self.qtime = GetTimeGame()
	end
end

function Janna:OnRemoveBuff(unit,buff)
	__PrintTextGame(buff.Name)
	if unit.IsMe then
		if buff.Name == "HowlingGale" then
			self.isQactive = false
		end
		if buff.Name == "ReapTheWhirlwind" then
			SetLuaMoveOnly(false)
			SetLuaBasicAttackOnly(false)
		end
	end
end

function Janna:logicQ()
	local target = GetTargetSelector(1700, 0)
	if CanCast(_Q) 
	and target ~= nil
	and not self.isQactive
	and not self.isRactive
	and IsValidTarget(target,1700)
	then
		if self.lastQtime == 0 
		or GetTimeGame() - self.lastQtime >= 1 
		and IsValidTarget(target,1500) 
		then
			targetQ = GetAIHero(target)
			local CastPosition, HitChance, Position = vpred:GetLineCastPosition(targetQ, 
			self.Q.delay, 
			self.Q.width, 
			self.Q.range, 
			self.Q.speed, 
			myHero, 
			false)
			CastSpellToPos(CastPosition.x, CastPosition.z, _Q)
			self.lastQtime = GetTimeGame()
		end
		return
	end
	
	if self.isQactive 
	and IsValidTarget(target,1700) 
	then
		targetQ = GetAIHero(target)
		local range = 900 + (GetTimeGame() - self.qtime)*233
		if range > GetDistance(targetQ.Addr) then
			CastSpellTarget(myHero.Addr,_Q)
		end
	end
end

function Janna:logicW()
	local target = GetTargetSelector(800, 0)
	if CanCast(_W) and IsValidTarget(target,self.W.range) then
		targetW = GetAIHero(target)
		CastSpellTarget(targetW.Addr,_W)
	end
end

function Janna:logicR()
	if self.use_R then
		for i, heros in ipairs(GetAllyHeroes()) do
			if heros ~= nil then
				local target = GetAIHero(heros)
				if target.HP / target.MaxHP * 100 <= self.use_R_HP then
					if CanCast(_R) and IsValidTarget(target,self.R.range) then
						CastSpellTarget(myHero.Addr, _R)
						SetLuaMoveOnly(true)
						SetLuaBasicAttackOnly(true)
					end
				end
			end
		end
	end
end
function Janna:MenuBool(stringKey, bool)
	return ReadIniBoolean(self.menu, stringKey, bool)
end

function Janna:MenuSliderInt(stringKey, valueDefault)
	return ReadIniInteger(self.menu, stringKey, valueDefault)
end

function Janna:MenuKeyBinding(stringKey, valueDefault)
	return ReadIniInteger(self.menu, stringKey, valueDefault)
end