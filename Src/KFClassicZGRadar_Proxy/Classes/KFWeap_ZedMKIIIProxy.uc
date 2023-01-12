class KFWeap_ZedMKIIIProxy extends Object;

stripped simulated event context(KFWeap_ZedMKIII.PostBeginPlay) PostBeginPlay()
{
	Super.PostBeginPlay();
	Spawn(class'KFClassicZGRadar.KFZEDGun_Helper', self,, Location, Rotation);
	CosTargetAngle = Cos(MaxTargetAngle * DegToRad);
}

stripped function context(KFWeap_ZedMKIII.ItemRemovedFromInvManager) ItemRemovedFromInvManager()
{
	ItemRemovedFromInvManagerEx();
}

stripped final simulated function context(KFWeap_ZedMKIII) ItemRemovedFromInvManagerEx()
{
	local KFZEDGun_Helper Helper;
	
	Super.ItemRemovedFromInvManager();

	Helper = class'KFZEDGun_Helper'.static.FindZEDGunHelper(self);
	if( Helper != None )
		Helper.Destroy();
}

stripped reliable client function context(KFWeap_ZedMKIII.ClientWeaponSet) ClientWeaponSet(bool bOptionalSet, optional bool bDoNotActivate)
{
	ClientWeaponSetEx(bOptionalSet, bDoNotActivate);
}

stripped final simulated function context(KFWeap_ZedMKIII) ClientWeaponSetEx(bool bOptionalSet, optional bool bDoNotActivate)
{
	local KFZEDGun_Helper Helper;

	Super.ClientWeaponSet(bOptionalSet, bDoNotActivate);

	Helper = class'KFZEDGun_Helper'.static.FindZEDGunHelper(self);
	if( Helper != None )
		Helper.SetupTexture();
}

stripped simulated function context(KFWeap_ZedMKIII.StartRadar) StartRadar()
{
	return;
}

stripped simulated function context(KFWeap_ZedMKIII.StopRadar) StopRadar()
{
	return;
}