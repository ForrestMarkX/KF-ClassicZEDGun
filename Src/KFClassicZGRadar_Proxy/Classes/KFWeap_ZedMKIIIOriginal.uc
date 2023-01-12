class KFWeap_ZedMKIIIOriginal extends Object;

simulated event PostBeginPlay();
function ItemRemovedFromInvManager();
reliable client function ClientWeaponSet(bool bOptionalSet, optional bool bDoNotActivate);
simulated function StartRadar();
simulated function StopRadar();