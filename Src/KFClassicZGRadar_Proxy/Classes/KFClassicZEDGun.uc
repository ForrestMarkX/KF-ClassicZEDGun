class KFClassicZEDGun extends KFMutator;

var const private bool bZEDNetworkUpdated;
var transient KFRealtimeTimerHelper TimerHelper;
var transient array<KFWeap_ZedMKIII> ZEDGunList;

simulated function PreBeginPlay()
{
	if( WorldInfo.NetMode == NM_DedicatedServer )
		TimerHelper = Spawn(class'KFRealtimeTimerHelper');
    Super.PreBeginPlay();
}

simulated function PostBeginPlay()
{
	local DummyMoviePlayer MoviePlayer;
	
	Super.PostBeginPlay();
	
	class'KFWeap_ZedMKIII'.default.PlayerViewOffset.X = 27;
	class'KFWeap_ZedMKIII'.default.MaxRadarDistance = 4000;
	
	if( WorldInfo.NetMode != NM_DedicatedServer )
	{
		KFWeap_ZedMKIIIOriginal.PostBeginPlay = KFWeap_ZedMKIII.PostBeginPlay;
		KFWeap_ZedMKIIIOriginal.ItemRemovedFromInvManager = KFWeap_ZedMKIII.ItemRemovedFromInvManager;
		KFWeap_ZedMKIIIOriginal.ClientWeaponSet = KFWeap_ZedMKIII.ClientWeaponSet;
		KFWeap_ZedMKIIIOriginal.StartRadar = KFWeap_ZedMKIII.StartRadar;
		KFWeap_ZedMKIIIOriginal.StopRadar = KFWeap_ZedMKIII.StopRadar;
		KFWeap_ZedMKIII.PostBeginPlay = KFWeap_ZedMKIIIProxy.PostBeginPlay;
		KFWeap_ZedMKIII.ItemRemovedFromInvManager = KFWeap_ZedMKIIIProxy.ItemRemovedFromInvManager;
		KFWeap_ZedMKIII.ClientWeaponSet = KFWeap_ZedMKIIIProxy.ClientWeaponSet;
		KFWeap_ZedMKIII.StartRadar = KFWeap_ZedMKIIIProxy.StartRadar;
		KFWeap_ZedMKIII.StopRadar = KFWeap_ZedMKIIIProxy.StopRadar;
		
		MoviePlayer = New class'DummyMoviePlayer';
		MoviePlayer.Init();
		MoviePlayer.SetVisibility(false);
		MoviePlayer.SetMenuVisibility(false);
		MoviePlayer.SetWidgetsVisible(false);
		MoviePlayer.SetMovieCanReceiveInput(false);
		MoviePlayer.SetMovieCanReceiveFocus(false);
		MoviePlayer.ClearCaptureKeys();
		MoviePlayer.ClearFocusIgnoreKeys();
	}
	else TimerHelper.SetTimer(0.5f, true, 'UpdateRadarEntities', self);
}

// This is what happens when you don't have access to native replication - FMX
// Access to AKFPawn_Monster::IsNetRelevantFor would solve this problem right away
final function UpdateRadarEntities()
{
	local KFWeap_ZedMKIII ZEDGun;
	local KFPawn_Monster KFPM;
	
	if( KFGI.MyKFGRI.AIRemaining <= KFGI.GetNumAlwaysRelevantZeds() )
		return;
	
	foreach ZEDGunList(ZEDGun)
	{
		if( ZEDGun == None )
		{
			ZEDGunList.RemoveItem(ZEDGun);
			continue;
		}
		
		foreach CollidingActors(class'KFPawn_Monster', KFPM, ZEDGun.MaxRadarDistance, ZEDGun.Instigator.Location, true)
		{
			if( !bZEDNetworkUpdated )
				bZEDNetworkUpdated = true;
			KFPM.bAlwaysRelevant = true;
		}
	}
	
	if( ZEDGunList.Length == 0 && bZEDNetworkUpdated )
	{
		foreach WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
		{
			if( !KFPM.default.bAlwaysRelevant )
				KFPM.bAlwaysRelevant = false;
		}
		bZEDNetworkUpdated = false;
	}
}

function bool CheckReplacement(Actor Other)
{
	if( KFWeap_ZedMKIII(Other) != None )
		ZEDGunList.AddItem(KFWeap_ZedMKIII(Other));
	return true;
}

defaultproperties
{
	bAlwaysRelevant=true
	RemoteRole=ROLE_SimulatedProxy
}