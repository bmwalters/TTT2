if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_ttt2_base"

if CLIENT then
	SWEP.PrintName	= "HL2 SMG"
	SWEP.Author		= "Zerf"
	SWEP.Category	= "TTT"

	SWEP.DrawCrosshair	= true
	SWEP.DrawAmmo		= true
end

SWEP.Slot		= 2

SWEP.Spawnable	= false
SWEP.AdminOnly	= false

SWEP.ViewModelFOV	= 54
SWEP.ViewModel		= "models/weapons/c_smg1.mdl"
SWEP.WorldModel		= "models/weapons/w_smg1.mdl"
SWEP.ViewModelFlip	= false
SWEP.UseHands		= true
SWEP.HoldType		= "smg"
SWEP.DeploySpeed	= 1.0

SWEP.AutoSwitchTo	= true
SWEP.AutoSwitchFrom	= false

SWEP.FiresUnderwater = false

SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "SMG1"
SWEP.Primary.ClipSize		= 50
SWEP.Primary.DefaultClip	= 200
SWEP.Primary.Damage		= 15
SWEP.Primary.TakeAmmo	= 1
SWEP.Primary.Spread		= 0.1
SWEP.Primary.NumShots	= 1
SWEP.Primary.Recoil		= 0.3
SWEP.Primary.Delay		= 0.08
SWEP.Primary.Force		= 6

SWEP.Secondary = {}

SWEP.HeadshotMultiplier = 2.7

SWEP.IronSightsPos = Vector(-6.43, -8.881, 1.039)
SWEP.IronSightsAng = Vector(0.1, -0.101, -0.201)
SWEP.IronSightsFOV = 0

SWEP.Sounds = {
	shoot = Sound("Weapon_SMG1.Single"),
	reload = Sound("Weapon_SMG1.Reload"),
	empty = Sound("Weapon_SMG1.Empty"),
}
