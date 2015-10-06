if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_base"

if CLIENT then
	SWEP.PrintName	= "TTT2 Base"
	SWEP.Author		= "Zerf, Bad King, Clavus"
	SWEP.Category	= "TTT"

	SWEP.DrawCrosshair	= true
	SWEP.DrawAmmo		= true
end

SWEP.Slot		= 1

SWEP.Spawnable	= true
SWEP.AdminOnly	= false

SWEP.ViewModelFOV	= 54
SWEP.ViewModel		= "models/weapons/c_pistol.mdl"
SWEP.WorldModel		= "models/weapons/w_pistol.mdl"
SWEP.ViewModelFlip	= false
SWEP.UseHands		= true
SWEP.HoldType		= "pistol"
SWEP.DeploySpeed	= 1.0

SWEP.AutoSwitchTo	= true
SWEP.AutoSwitchFrom	= false

SWEP.FiresUnderwater = false

SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "pistol"
SWEP.Primary.ClipSize		= 50
SWEP.Primary.DefaultClip	= 100
SWEP.Primary.Damage		= 20
SWEP.Primary.TakeAmmo	= 1
SWEP.Primary.Spread		= 0.1
SWEP.Primary.NumShots	= 1
SWEP.Primary.Recoil		= 0.3
SWEP.Primary.Delay		= 0.3
SWEP.Primary.Force		= 6

SWEP.Secondary = {}

SWEP.HeadshotMultiplier = 2.7
SWEP.StoredAmmo = 0

SWEP.IronSightsPos = Vector(-5.75, -14, 2.4)
SWEP.IronSightsAng = Vector(2.6, -1.5, 1.5)
SWEP.IronSightsFOV = 0

SWEP.Sounds = {
	shoot = Sound("Weapon_Pistol.Single"),
	reload = Sound("Weapon_Pistol.Reload"),
	empty = Sound("Weapon_Pistol.Empty"),
}

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	self:SetDeploySpeed(self.DeploySpeed)

	if self.Primary.Spread then
		self.Primary.SpreadIron = self.Primary.SpreadIron or self.Primary.Spread * 0.85
		self.Primary.RecoilIron = self.Primary.RecoilIron or self.Primary.Recoil * 0.6
	end

	if self.IronSightsPos or self.IronSightsAng or self.IronSightsFOV then
		self:SetIronSights(false)
	end

	if CLIENT then
		self:SCK_Initialize()
	end
end

local SF_WEAPON_START_CONSTRAINED = 1

function SWEP:Equip(newowner)
	if SERVER then
		--[[
		if self:HasSpawnFlags(SF_WEAPON_START_CONSTRAINED) then
			-- If this weapon started constrained, unset that spawnflag, or the weapon will be re-constrained and float
			local flags = self:GetSpawnFlags()
			local newflags = bit.band(flags, bit.bnot(SF_WEAPON_START_CONSTRAINED))
			self:SetKeyValue("spawnflags", newflags)
		end
		--]]
		if IsValid(newowner) and self.StoredAmmo > 0 and self.Primary.Ammo ~= "none" then
			local ammo = newowner:GetAmmoCount(self.Primary.Ammo)
			local given = math.min(self.StoredAmmo, self.Primary.ClipMax - ammo)

			newowner:GiveAmmo(given, self.Primary.Ammo)
			self.StoredAmmo = 0
		end
	end
end

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_VM_DRAW)
	self:SetIronSights(false)
	return true
end

function SWEP:Holster()
	if CLIENT and self.SCK then self:SCK_Holster() end
	return true
end

function SWEP:OnRemove()
	if CLIENT and self.SCK then self.SCK_OnRemove() end
	return true
end

function SWEP:CanPrimaryAttack()
	if self:Clip1() <= 0 then
		if self.Sounds.empty then self:EmitSound(self.Sounds.empty) end
		self:Reload()
		return false
	end

	if self:GetOwner():WaterLevel() >= 3 and not self.FiresUnderwater then
		if self.Sounds.empty then self:EmitSound(self.Sounds.empty) end
		return false
	end

	return true
end

function SWEP:CanReload()
	if self.ReloadingTime and CurTime() <= self.ReloadingTime then return false end
	if self:Clip1() >= self.Primary.ClipSize then return false end
	if self:GetOwner():GetAmmoCount(self.Primary.Ammo) <= 0 then self:SetNextPrimaryFire(CurTime() + 0.5) return false end

	return true
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	local owner = self:GetOwner()
	local sights = self:GetIronSights()

	local acc = sights and self.Primary.SpreadIron or self.Primary.Spread

	local bullet = {}
	bullet.Num		= self.Primary.NumShots
	bullet.Src		= owner:GetShootPos()
	bullet.Dir		= owner:GetAimVector()
	bullet.Spread	= Vector(acc, acc, 0)
	bullet.Tracer	= TRACER_NONE
	bullet.Force	= self.Primary.Force or 6
	bullet.Damage	= self.Primary.Damage
	bullet.AmmoType	= self.Primary.Ammo

	owner:FireBullets(bullet)

	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	owner:MuzzleFlash()
	owner:SetAnimation(PLAYER_ATTACK1)

	if self.Sounds.shoot then self:EmitSound(self.Sounds.shoot) end

	-- local rnda = self.Recoil * -1
	-- local rndb = self.Recoil * math.random(-1, 1)
	-- owner:ViewPunch(Angle(rnda, rndb, rnda))
	if CLIENT and IsFirstTimePredicted() then
		local recoil = sights and self.Primary.RecoilIron or self.Primary.Recoil
		local eyeang = owner:EyeAngles()
		eyeang.p = eyeang.p - recoil
		owner:SetEyeAngles(eyeang)
	end

	self:TakePrimaryAmmo(self.Primary.TakeAmmo)

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
	self.ReloadingTime = CurTime() + self.Primary.Delay
end

-- I'm not even sure where this is used, but it exists in TTT.
function SWEP:GetHeadshotMultiplier(victim, dmginfo)
	return self.HeadshotMultiplier
end

function SWEP:Reload()
	if not self:CanReload() then return end

	local owner = self:GetOwner()

	self:SetIronSights(false)
	local ammocnt = math.Clamp(self.Primary.ClipSize - self:Clip1(), 0, self:Ammo1())
	owner:RemoveAmmo(ammocnt, self.Primary.Ammo)
	self:SetClip1(self:Clip1() + ammocnt)

	self:SendWeaponAnim(ACT_VM_RELOAD)
	owner:SetAnimation(PLAYER_RELOAD)
	local animtime = owner:GetViewModel():SequenceDuration()
	self.ReloadingTime = CurTime() + animtime
	self:SetNextPrimaryFire(CurTime() + animtime)
	if self.Sounds.reload then self:EmitSound(self.Sounds.reload, nil, nil, nil, CHAN_WEAPON) end -- CHAN_ITEM
end

function SWEP:PreDrop()
	local owner = self:GetOwner()
	if SERVER and IsValid(owner) and self.Primary.Ammo != "none" then
		local ammo = self:Ammo1()

		-- Do not drop ammo if we have another gun that uses this type
		for _, w in pairs(owner:GetWeapons()) do
			if IsValid(w) and w != self and w:GetPrimaryAmmoType() == self:GetPrimaryAmmoType() then
				ammo = 0
			end
		end

		self.StoredAmmo = ammo

		if ammo > 0 then
			owner:RemoveAmmo(ammo, self.Primary.Ammo)
		end
	end
end

function SWEP:DampenDrop()
	-- Dampen drop velocity so weapons don't catapult away from body
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetVelocityInstantaneous(Vector(0, 0, -75) + phys:GetVelocity() * 0.001)
		phys:AddAngleVelocity(phys:GetAngleVelocity() * -0.99)
	end
end

-- Ironsight BS
local ironsight_time = 0.25

SWEP.NextSecondaryAttack = 0
function SWEP:SecondaryAttack()
	if not self.IronSightsPos then return end
	if self.NextSecondaryAttack > CurTime() then return end

	self:SetIronSights(not self:GetIronSights())

	self.NextSecondaryAttack = CurTime() + ironsight_time + 0.5
end

function SWEP:SetIronSights(b)
	local fov = b and self.IronSightsFOV or 0

	local owner = self:GetOwner()
	if IsValid(owner) and owner:IsPlayer() then
		self:GetOwner():SetFOV(fov, 0.4)
	end

	self:SetNWBool("IronSights", b)
end

function SWEP:GetIronSights()
	return self:GetNWBool("IronSights", false)
end

function SWEP:GetViewModelPosition(pos, ang)
	if not (self.IronSightsPos or self.IronSightsAng) then return pos, ang end

	local ironsights = self:GetIronSights()

	if ironsights ~= self.LastIron then
		self.LastIron = ironsights
		self.IronTime = CurTime()

		self.SwayScale = ironsights and 0.3 or 1.0
		self.BobScale = ironsights and 0.1 or 1.0
	end

	local irontime = self.IronTime or 0

	if irontime < (CurTime() - ironsight_time) and not ironsights then
		return pos, ang
	end

	local mul = 1.0

	if irontime > CurTime() - ironsight_time then
		mul = math.Clamp((CurTime() - irontime) / ironsight_time, 0, 1)
		if not ironsights then mul = 1 - mul end
	end

	local offset = self.IronSightsPos

	if self.IronSightsAng then
		ang = ang * 1
		ang:RotateAroundAxis(ang:Right(), self.IronSightsAng.x * mul)
		ang:RotateAroundAxis(ang:Up(), self.IronSightsAng.y * mul)
		ang:RotateAroundAxis(ang:Forward(), self.IronSightsAng.z * mul)
	end

	pos = pos + offset.x * ang:Right()   * mul
	pos = pos + offset.y * ang:Forward() * mul
	pos = pos + offset.z * ang:Up()      * mul

	return pos, ang
end

if CLIENT then
	function SWEP:DoDrawCrosshair(x, y)
		local client = LocalPlayer()

		local sights = self:GetIronSights()

		local LastShootTime = self:LastShootTime()

		local acc = sights and self.Primary.SpreadIron or self.Primary.Spread

		local scale = math.max(0.2,  8 * acc)
		scale = scale * (2 - math.Clamp((CurTime() - LastShootTime) * 5, 0.0, 1.0))

		local alpha = sights and 0.8 or 1
		local bright = 1

		if client.Role == ROLE_TRAITOR then
			surface.SetDrawColor(255 * bright, 50 * bright, 50 * bright, 255 * alpha)
		else
			surface.SetDrawColor(0, 255 * bright, 0, 255 * alpha)
		end

		local gap = math.floor(20 * scale * (sights and 0.8 or 1))
		local length = math.floor(gap + (25 * 1) * scale)
		surface.DrawLine(x - length, y, x - gap, y)
		surface.DrawLine(x + length, y, x + gap, y)
		surface.DrawLine(x, y - length, x, y - gap)
		surface.DrawLine(x, y + length, x, y + gap)

		return true
	end

	function SWEP:ViewModelDrawn(vm)
		if self.SCK then self:SCK_ViewModelDrawn(vm) end
	end

	function SWEP:DrawWorldModel()
		if self.SCK then
			self:SCK_DrawWorldModel()
		else
			self:DrawModel()
		end
	end

	-- SWEP construction kit garbage
	local FullCopy = table.FullCopy or function(tab)
		-- Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
		-- Does not copy entities of course, only copies their reference.
		-- WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
		if not tab then return end

		local res = {}
		for k, v in pairs(tab) do
			local t = type(v)
			if t == "table" then
				res[k] = FullCopy(v) -- recursion ho!
			elseif t == "Vector" then
				res[k] = Vector(v.x, v.y, v.z)
			elseif t == "Angle" then
				res[k] = Angle(v.p, v.y, v.r)
			else
				res[k] = v
			end
		end

		return res
	end

	--[[-----------------------------------------------------
		SWEP Construction Kit base code
			Created by Clavus
		Available for public use, thread at:
			facepunch.com/threads/1032378
	-----------------------------------------------------]]--
	local color_transparent1 = Color(255, 255, 255, 1)
	function SWEP:SCK_Initialize()
		self.SCK = (self.VElements or self.WElements) ~= nil

		if not self.SCK then return end

		if CLIENT then
			self.VElements = FullCopy(self.VElements)
			self.WElements = FullCopy(self.WElements)
			self.ViewModelBoneMods = FullCopy(self.ViewModelBoneMods)

			self:SCK_CreateModels(self.VElements) -- create viewmodels
			self:SCK_CreateModels(self.WElements) -- create worldmodels

			-- init view model bone build function
			local owner = self:GetOwner()
			if IsValid(owner) then
				local vm = owner:GetViewModel()
				if IsValid(vm) then
					self:SCK_ResetBonePositions(vm)

					-- Init viewmodel visibility
					if self.ShowViewModel ~= false then
						vm:SetColor(color_white)
					else
						-- we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
						vm:SetColor(color_transparent1)
						-- ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
						-- however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
						vm:SetMaterial("debug/hsv")
					end
				end
			end
		end
	end

	function SWEP:SCK_Holster()
		local owner = self:GetOwner()
		if IsValid(owner) then
			local vm = owner:GetViewModel()
			if IsValid(vm) then
				self:SCK_ResetBonePositions(vm)
			end
		end
	end

	SWEP.vRenderOrder = nil
	function SWEP:SCK_ViewModelDrawn(vm)
		if not IsValid(vm) then return end

		if not self.VElements then return end

		self:SCK_UpdateBonePositions(vm)

		if not self.vRenderOrder then
			-- we build a render order because sprites need to be drawn after models
			self.vRenderOrder = {}

			for k, v in pairs(self.VElements) do
				if v.type == "Model" then
					table.insert(self.vRenderOrder, 1, k)
				elseif v.type == "Sprite" or v.type == "Quad" then
					table.insert(self.vRenderOrder, k)
				end
			end
		end

		for k, name in ipairs(self.vRenderOrder) do
			local v = self.VElements[name]
			if not v then self.vRenderOrder = nil break end
			if v.hide then continue end

			local model = v.modelEnt
			local sprite = v.spriteMaterial

			if not v.bone then continue end

			local pos, ang = self:SCK_GetBoneOrientation(self.VElements, v, vm)

			if not pos then continue end

			if v.type == "Model" and IsValid(model) then
				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				-- model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix("RenderMultiply", matrix)

				if v.material == "" then
					model:SetMaterial("")
				elseif model:GetMaterial() ~= v.material then
					model:SetMaterial(v.material)
				end

				if v.skin and v.skin ~= model:GetSkin() then
					model:SetSkin(v.skin)
				end

				if v.bodygroup then
					for k, v in pairs(v.bodygroup) do
						if model:GetBodygroup(k) ~= v then
							model:SetBodygroup(k, v)
						end
					end
				end

				if v.surpresslightning then -- nice typo; can't change because it breaks compat :(
					render.SuppressEngineLighting(true)
				end

				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
					model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)

				if v.surpresslightning then
					render.SuppressEngineLighting(false)
				end
			elseif v.type == "Sprite" and sprite then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
			elseif v.type == "Quad" and v.draw_func then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func(self)
				cam.End3D2D()
			end
		end
	end

	SWEP.wRenderOrder = nil
	function SWEP:SCK_DrawWorldModel()
		if self.ShowWorldModel ~= false then
			self:DrawModel()
		end

		if not self.WElements then return end

		if not self.wRenderOrder then
			self.wRenderOrder = {}

			for k, v in pairs(self.WElements) do
				if v.type == "Model" then
					table.insert(self.wRenderOrder, 1, k)
				elseif v.type == "Sprite" or v.type == "Quad" then
					table.insert(self.wRenderOrder, k)
				end
			end
		end

		local owner = self:GetOwner()
		if IsValid(owner) then
			bone_ent = owner
		else
			-- when the weapon is dropped
			bone_ent = self
		end

		for k, name in pairs(self.wRenderOrder) do
			local v = self.WElements[name]
			if not v then self.wRenderOrder = nil break end
			if v.hide then continue end

			local pos, ang

			if v.bone then
				pos, ang = self:SCK_GetBoneOrientation(self.WElements, v, bone_ent)
			else
				pos, ang = self:SCK_GetBoneOrientation(self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand")
			end

			if not pos then continue end

			local model = v.modelEnt
			local sprite = v.spriteMaterial

			if v.type == "Model" and IsValid(model) then
				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				-- model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix("RenderMultiply", matrix)

				if v.material == "" then
					model:SetMaterial("")
				elseif model:GetMaterial() ~= v.material then
					model:SetMaterial(v.material)
				end

				if v.skin and v.skin ~= model:GetSkin() then
					model:SetSkin(v.skin)
				end

				if v.bodygroup then
					for k, v in pairs(v.bodygroup) do
						if model:GetBodygroup(k) ~= v then
							model:SetBodygroup(k, v)
						end
					end
				end

				if v.surpresslightning then
					render.SuppressEngineLighting(true)
				end

				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
					model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)

				if v.surpresslightning then
					render.SuppressEngineLighting(false)
				end
			elseif v.type == "Sprite" and sprite then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
			elseif v.type == "Quad" and v.draw_func then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func(self)
				cam.End3D2D()
			end
		end
	end

	function SWEP:SCK_GetBoneOrientation(basetab, tab, ent, bone_override)
		local bone, pos, ang
		if tab.rel ~= "" then
			local v = basetab[tab.rel]

			if not v then return end

			-- Technically, if there exists an element with the same name as a bone
			-- you can get in an infinite loop. Let's just hope nobody's that stupid.
			pos, ang = self:SCK_GetBoneOrientation(basetab, v, ent)

			if not pos then return end

			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
		else
			bone = ent:LookupBone(bone_override or tab.bone)

			if not bone then return end

			pos, ang = vector_origin, angle_zero
			local m = ent:GetBoneMatrix(bone)
			if m then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end

			local owner = self:GetOwner()
			if IsValid(owner) and owner:IsPlayer() and ent == owner:GetViewModel() and self.ViewModelFlip then
				ang.r = -ang.r -- Fixes mirrored models
			end
		end

		return pos, ang
	end

	function SWEP:SCK_CreateModels(tab)
		if not tab then return end

		-- Create the clientside models here because Garry says we can't do it in the render hook
		for k, v in pairs(tab) do
			if v.type == "Model" and v.model ~= "" and not (IsValid(v.modelEnt) and v.createdModel == v.model) then
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
				if IsValid(v.modelEnt) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel = v.model
				else
					pcall(function() v.modelEnt:Remove() end) -- due to a current bug, we have to remove this manually
					v.modelEnt = nil
				end
			elseif v.type == "Sprite" and v.sprite ~= "" and not (v.spriteMaterial and v.createdSprite == v.sprite) then
				local name = v.sprite.."-"
				local params = {["$basetexture"] = v.sprite}
				-- make sure we create a unique name based on the selected options
				local tocheck = {"nocull", "additive", "vertexalpha", "vertexcolor", "ignorez"}
				for i, param in pairs(tocheck) do
					if v[param] then
						params["$"..param] = 1
						name = name.."1"
					else
						name = name.."0"
					end
				end

				v.createdSprite = v.sprite
				v.spriteMaterial = CreateMaterial(name, "UnlitGeneric", params)
			end
		end
	end

	local allbones
	local hasGarryFixedBoneScalingYet = false

	function SWEP:SCK_UpdateBonePositions(vm)
		if self.ViewModelBoneMods then
			if not vm:GetBoneCount() then return end

			-- WORKAROUND --
			-- We need to check all model names :/
			local loopthrough = self.ViewModelBoneMods
			if not hasGarryFixedBoneScalingYet then
				allbones = {}
				for i = 0, vm:GetBoneCount() do
					local bonename = vm:GetBoneName(i)
					if self.ViewModelBoneMods[bonename] then
						allbones[bonename] = self.ViewModelBoneMods[bonename]
					else
						allbones[bonename] = {
							scale = Vector(1, 1, 1),
							pos = Vector(0, 0, 0),
							angle = Angle(0, 0, 0),
						}
					end
				end

				loopthrough = allbones
			end
			-- END WORKAROUND --

			for k, v in pairs(loopthrough) do
				local bone = vm:LookupBone(k)
				if not bone then continue end

				-- WORKAROUND --
				local s = Vector(v.scale.x, v.scale.y, v.scale.z)
				local p = Vector(v.pos.x, v.pos.y, v.pos.z)
				local ms = Vector(1, 1, 1)
				if not hasGarryFixedBoneScalingYet then
					local cur = vm:GetBoneParent(bone)
					while cur >= 0 do
						local pscale = loopthrough[vm:GetBoneName(cur)].scale
						ms = ms * pscale
						cur = vm:GetBoneParent(cur)
					end
				end

				s = s * ms
				-- END WORKAROUND --

				if vm:GetManipulateBoneScale(bone) ~= s then
					vm:ManipulateBoneScale(bone, s)
				end
				if vm:GetManipulateBoneAngles(bone) ~= v.angle then
					vm:ManipulateBoneAngles(bone, v.angle)
				end
				if vm:GetManipulateBonePosition(bone) ~= p then
					vm:ManipulateBonePosition(bone, p)
				end
			end
		else
			self:SCK_ResetBonePositions(vm)
		end
	end

	function SWEP:SCK_ResetBonePositions(vm)
		if not vm:GetBoneCount() then return end
		for i = 0, vm:GetBoneCount() do
			vm:ManipulateBoneScale(i, Vector(1, 1, 1))
			vm:ManipulateBoneAngles(i, Angle(0, 0, 0))
			vm:ManipulateBonePosition(i, Vector(0, 0, 0))
		end
	end

	function SWEP:SCK_OnRemove()
		if self.VElements then
			for k, v in pairs(self.VElements) do
				if v.modelEnt then
					pcall(function() v.modelEnt:Remove() end) -- due to a current bug, we have to remove this manually
				end
			end
		end
		if self.VElements then
			for k, v in pairs(self.WElements) do
				if v.modelEnt then
					pcall(function() v.modelEnt:Remove() end) -- due to a current bug, we have to remove this manually
				end
			end
		end
	end
end
