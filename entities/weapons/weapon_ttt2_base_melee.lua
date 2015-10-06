if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_ttt2_base"

if CLIENT then
	SWEP.PrintName	= "TTT2 Base Melee"
	SWEP.Author		= "Zerf, GMod Team"
	SWEP.Category	= "TTT"

	SWEP.DrawCrosshair	= true
	SWEP.DrawAmmo		= true
end

SWEP.Slot		= 0

SWEP.Spawnable	= false
SWEP.AdminOnly	= false

SWEP.ViewModelFOV	= 54
SWEP.ViewModel		= "models/weapons/c_crowbar.mdl"
SWEP.WorldModel		= "models/weapons/w_crowbar.mdl"
SWEP.ViewModelFlip	= false
SWEP.UseHands		= true
SWEP.HoldType		= "melee"
SWEP.DeploySpeed	= 2.0

SWEP.AutoSwitchTo	= true
SWEP.AutoSwitchFrom	= false

SWEP.FiresUnderwater = true

SWEP.Primary.Automatic	= true
SWEP.Primary.Ammo		= "none"
SWEP.Primary.Damage		= 15
SWEP.Primary.Recoil		= 0.3
SWEP.Primary.Delay		= 0.5
SWEP.Primary.Force		= 60

SWEP.Secondary = {}

SWEP.HitDistance = 100
SWEP.HeadshotMultiplier = 1.0

SWEP.Sounds = {
	swing = Sound("Weapon_Crowbar.Single"),
	hit = Sound("Weapon_Crowbar.Melee_Hit"),
	hitworld = Sound("Weapon_Crowbar.Melee_HitWorld"),
}

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	self:SetDeploySpeed(self.DeploySpeed)

	if CLIENT then
		self:SCK_Initialize()
	end
end

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_VM_DRAW)
	return true
end

function SWEP:CanPrimaryAttack()
	if self:GetOwner():WaterLevel() >= 3 and not self.FiresUnderwater then
		return false
	end

	return true
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	local owner = self:GetOwner()

	owner:SetAnimation(PLAYER_ATTACK1)

	if self.Sounds.swing then self:EmitSound(self.Sounds.swing) end

	owner:LagCompensation(true)

	local td = {
		start = owner:GetShootPos(),
		endpos = owner:GetShootPos() + owner:GetAimVector() * self.HitDistance,
		filter = owner,
		mask = MASK_SHOT_HULL,
	}

	local tr = util.TraceLine(td)

	if not IsValid(tr.Entity) then
		td.mins = Vector(-10, -10, -8)
		td.maxs = Vector(10, 10, 8)

		tr = util.TraceHull(td)
	end

	if tr.Hit and not tr.HitWorld then
		self:SendWeaponAnim(ACT_VM_HITCENTER)
	else
		self:SendWeaponAnim(ACT_VM_MISSCENTER)
	end

	if tr.HitWorld and self.Sounds.hitworld then
		self:EmitSound(self.Sounds.hitworld)
	elseif tr.Hit and self.Sounds.hit then
		self:EmitSound(self.Sounds.hit)
	end

	if tr.Hit then
		local edata = EffectData()
		edata:SetStart(owner:GetShootPos())
		edata:SetOrigin(tr.HitPos)
		edata:SetNormal(tr.Normal)
		edata:SetSurfaceProp(tr.SurfaceProps)
		edata:SetHitBox(tr.HitBox)
		-- edata:SetDamageType(DMG_CLUB)
		edata:SetEntity(tr.Entity)
		util.Effect((IsValid(tr.Entity) and tr.Entity:IsNPC() or tr.Entity:IsPlayer() or tr.Entity:IsRagdoll()) and "BloodImpact" or "Impact", edata)
	end

	if SERVER and IsValid(tr.Entity) then
		if tr.Entity:IsNPC() or tr.Entity:IsPlayer() or tr.Entity:Health() > 0 then
			local dmginfo = DamageInfo()

			local attacker = owner
			if not IsValid(attacker) then attacker = self end
			dmginfo:SetAttacker(attacker)

			dmginfo:SetInflictor(self)
			dmginfo:SetDamage(self.Primary.Damage)
			dmginfo:SetDamagePosition(owner:GetPos())
			dmginfo:SetDamageForce(owner:GetAimVector() * 1500)

			tr.Entity:TakeDamageInfo(dmginfo)
		end

		local phys = tr.Entity:GetPhysicsObject()
		if IsValid(phys) then
			phys:ApplyForceOffset(owner:GetAimVector() * self.Primary.Force * phys:GetMass(), tr.HitPos)
		end
	end

	owner:LagCompensation(false)

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
end

-- I'm not even sure where this is used, but it exists in TTT.
function SWEP:GetHeadshotMultiplier(victim, dmginfo)
	return self.HeadshotMultiplier
end

function SWEP:Reload()
end

function SWEP:PreDrop()
end

function SWEP:SecondaryAttack()
end
