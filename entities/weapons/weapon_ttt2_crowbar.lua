if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_ttt2_base_melee"

if CLIENT then
	SWEP.PrintName	= "TTT2 Base Melee"
	SWEP.Author		= "Zerf"
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
SWEP.Primary.Damage		= 20
SWEP.Primary.Recoil		= 0.3
SWEP.Primary.Delay		= 0.5
SWEP.Primary.Force		= 60

SWEP.Secondary = {}

SWEP.HitDistance = 100
SWEP.HeadshotMultiplier = 1.0

SWEP.Sounds = {
	swing = Sound("Weapon_Crowbar.Single"),
	hit = Sound("Weapon_Crowbar.Melee_Hit"),
	hitworld = nil,
}
