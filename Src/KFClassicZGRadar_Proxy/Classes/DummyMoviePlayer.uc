class DummyMoviePlayer extends KFGFxMoviePlayer_Manager;

function Init(optional LocalPlayer LocPlay)
{
	Super(GFxMoviePlayer).Init( LocPlay );
}

function OnCleanup()
{
	Super.OnCleanup();
	
	KFWeap_ZedMKIII.PostBeginPlay = KFWeap_ZedMKIIIOriginal.PostBeginPlay;
	KFWeap_ZedMKIII.ItemRemovedFromInvManager = KFWeap_ZedMKIIIOriginal.ItemRemovedFromInvManager;
	KFWeap_ZedMKIII.ClientWeaponSet = KFWeap_ZedMKIIIOriginal.ClientWeaponSet;
	KFWeap_ZedMKIII.StartRadar = KFWeap_ZedMKIIIOriginal.StartRadar;
	KFWeap_ZedMKIII.StopRadar = KFWeap_ZedMKIIIOriginal.StopRadar;
	
	class'KFWeap_ZedMKIII'.default.PlayerViewOffset.X = 22;
	class'KFWeap_ZedMKIII'.default.MaxRadarDistance = 2000;
}

function SetMenusOpen(bool bIsOpen)
{
	SetMovieCanReceiveInput(false);
}

function bool FilterButtonInput(int ControllerId, name ButtonName, EInputEvent InputEvent);
function OnClose();

defaultproperties
{
	bDisplayWithHudOff=false
	bAllowInput=false
	bAllowFocus=false
	bCaptureInput=false
	bCaptureMouseInput=false
}