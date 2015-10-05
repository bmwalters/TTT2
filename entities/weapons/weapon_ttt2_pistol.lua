if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_base_ttt2"

if CLIENT then
	SWEP.PrintName	= "HL2 Pistol"
	SWEP.Author		= "Zerf"
	SWEP.Category	= "TTT"

	SWEP.Slot		= 1
	SWEP.SlotPos	= 1

	SWEP.DrawCrosshair	= true
	SWEP.DrawAmmo		= true
end

SWEP.Spawnable	= false
SWEP.AdminOnly	= false

SWEP.ViewModelFOV	= 54
SWEP.ViewModel		= "models/weapons/c_pistol.mdl"
SWEP.WorldModel		= "models/weapons/w_pistol.mdl"
SWEP.ViewModelFlip	= false
SWEP.UseHands		= true
SWEP.HoldType		= "pistol"
SWEP.DeploySpeed	= 1.4

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

SWEP.ShootSound		= Sound("Weapon_Pistol.Single")
SWEP.ReloadSound	= Sound("Weapon_Pistol.Reload")
SWEP.EmptySound		= Sound("Weapon_Pistol.Empty")
