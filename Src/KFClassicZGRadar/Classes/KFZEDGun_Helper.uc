class KFZEDGun_Helper extends Info;

var ScriptedTexture CurrentST;
var Texture ScreenBG, ScreenEdgeGlow, SmallZEDDot, MediumZEDDot, LargeZEDDot, BossDot, DeathDot, RingTex, ArrowUpTex, ArrowDownTex;
var MaterialInstanceConstant RadarMIC;
var byte RadarSkinIndex;
var float RadarPulse, ScanPulse, ScanPulse2, PulseSeed, PulseSeed2, PulseAlpha, PulseAlpha2, PulseSize, PulseSize2, MinEnemyDist;
var int MetersDist;
var rotator FlippedRot;

struct FDeadZed
{
	var KFPawn_Monster P;
	var vector Location;
	var float TimeOfDeath;
};
var transient array<FDeadZed> DeadZEDs;
var transient array<KFPawn_Monster> ZEDCache;
var transient array< class<KFPawn_Monster> > EliteZEDCache;
var transient KFWeap_ZedMKIII WeaponOwner;

var array<KFZEDGun_Helper> CurrentHelpers;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	
	WeaponOwner = KFWeap_ZedMKIII(Owner);
	
	PulseSeed = RandRange(0.225f, 0.4235f);
	PulseSeed2 = RandRange(0.4996f, 0.6335f);
	PulseAlpha = RandRange(2.f, 10.f);
	PulseAlpha2 = RandRange(4.f, 12.f);
	PulseSize = RandRange(8.f, 24.f);
	PulseSize2 = RandRange(2.f, 12.f);
	
	WeaponOwner.SetTimer(WeaponOwner.RadarUpdateEntitiesTime, true, 'CacheAllZEDs', self);
	WeaponOwner.SetTimer(1.f, true, 'ClearDeadZEDs', self);
	
	default.CurrentHelpers.AddItem(self);
}

final static function KFZEDGun_Helper FindZEDGunHelper(KFWeap_ZedMKIII W)
{
	local int i;
	
	for( i=0; i<default.CurrentHelpers.Length; i++ )
	{
		if( default.CurrentHelpers[i].Owner == W )
			return default.CurrentHelpers[i];
	}
	
	return None;
}

final function CacheAllZEDs()
{
	local KFPawn_Monster P;
	local int i;
	
	ZEDCache.Length = 0;
	foreach WeaponOwner.CollidingActors(class'KFPawn_Monster', P, WeaponOwner.MaxRadarDistance, Instigator.Location, true)
	{
		if( P.IsSameTeam(Instigator) )
			continue;
			
		if( P.ElitePawnClass.Length > 0 )
		{
			for( i=0; i<P.ElitePawnClass.Length; i++ )
			{
				if( EliteZEDCache.Find(P.ElitePawnClass[i]) == INDEX_NONE )
					EliteZEDCache.AddItem(P.ElitePawnClass[i]);
			}
		}
		
		ZEDCache.AddItem(P);
	}
	ZEDCache.Sort(SortZEDPriority);
}

final function int SortZEDPriority(KFPawn_Monster PawnA, KFPawn_Monster PawnB)
{
	local int ZEDAPriority, ZEDBPriority;

	if( PawnA != None && PawnA.IsAliveAndWell() )
	{
		if( PawnA.IsABoss() )
			ZEDAPriority = 3;
		else if( EliteZEDCache.Find(PawnA.Class) != INDEX_NONE )
			ZEDAPriority = 1;
		else
		{
			switch( PawnA.MinSpawnSquadSizeType )
			{
				case EST_Large:
					if( KFPawn_ZedBloat(PawnA) != None )
						ZEDAPriority = 1;
					else ZEDAPriority = 2;
					break;
				case EST_Medium:
					ZEDAPriority = 1;
					break;
				case EST_Crawler:
				case EST_Small:
				default:
					ZEDAPriority = 0;
					break;
			}
		}
	}
	else ZEDAPriority = 0;
		
	if( PawnB != None && PawnB.IsAliveAndWell() )
	{
		if( PawnB.IsABoss() )
			ZEDBPriority = 3;
		else if( EliteZEDCache.Find(PawnB.Class) != INDEX_NONE )
			ZEDBPriority = 1;
		else
		{
			switch( PawnB.MinSpawnSquadSizeType )
			{
				case EST_Large:
					if( KFPawn_ZedBloat(PawnB) != None )
						ZEDBPriority = 1;
					else ZEDBPriority = 2;
					break;
				case EST_Medium:
					ZEDBPriority = 1;
					break;
				case EST_Crawler:
				case EST_Small:
				default:
					ZEDBPriority = 0;
					break;
			}
		}
	}
	else ZEDBPriority = 0;
	
    return ZEDAPriority == ZEDBPriority ? (VSizeSq(PawnA.Location - Instigator.Location) < VSizeSq(PawnB.Location - Instigator.Location) ? -1 : 0) : (ZEDAPriority > ZEDBPriority ? -1 : 0);
}

final function ClearDeadZEDs()
{
	local FDeadZed Info;
	
	foreach DeadZEDs(Info)
	{
		if( Info.P == None )
			DeadZEDs.RemoveItem(Info);
	}
}

function Tick(float DT)
{
	Super.Tick(DT);
	
	if( Owner == None )
	{
		Destroy();
		return;
	}
	
	Instigator = WeaponOwner.Instigator;
	
	RadarPulse += 0.5f * DT;
	if( RadarPulse >= 1 )
	{
		if( MinEnemyDist < 1.f )
			MetersDist = (MinEnemyDist * WeaponOwner.MaxRadarDistance) / 100.f;
		else MetersDist = 0;
		
		RadarPulse = RadarPulse - 1;
	}
	
	ScanPulse += PulseSeed * DT;
	if( ScanPulse >= 1 )
	{
		ScanPulse = ScanPulse - 1;
		PulseSeed = RandRange(0.225f, 0.4235f);
		PulseAlpha = RandRange(2.f, 10.f);
		PulseSize = RandRange(8.f, 24.f);
	}
	
	ScanPulse2 += PulseSeed2 * DT;
	if( ScanPulse2 >= 1 )
	{
		ScanPulse2 = ScanPulse2 - 1;
		PulseSeed2 = RandRange(0.4996f, 0.6335f);
		PulseAlpha2 = RandRange(2.f, 10.f);
		PulseSize2 = RandRange(2.f, 12.f);
	}
}

final function SetupTexture()
{
	local LinearColor ClearColor, RadarColor;

	if( CurrentST == None )
	{
		ClearColor = MakeLinearColor(0, 0, 0, 1.f);
		RadarColor = MakeLinearColor(0.15f, 0.5f, 1.f, 1.f);
		
		CurrentST = ScriptedTexture(class'ScriptedTexture'.static.Create(512, 512,, ClearColor));
		CurrentST.Render = RenderRadar;
		
		RadarMIC = New(WeaponOwner.MySkelMesh) class'MaterialInstanceConstant';
		RadarMIC.SetParent(MaterialInstanceConstant'CHR_CosmeticSet17_MAT.holoarmband.CHR_Cyberpunk_Holo_Armband_1_MIC');
		RadarMIC.SetTextureParameterValue('Tex2d_HoloFX', CurrentST);
		RadarMIC.SetTextureParameterValue('Tex2d_Mask', CurrentST);
		RadarMIC.SetVectorParameterValue('Vector_Glow_Color', RadarColor);
		RadarMIC.SetScalarParameterValue('Scalar_FXBrightness', 1.25f);
		RadarMIC.SetScalarParameterValue('Scalar_FXContrast', 0.25f);
		
		WeaponOwner.MySkelMesh.SetMaterial(RadarSkinIndex, RadarMIC);
		WeaponOwner.MySkelMesh.SetMaterial(RadarSkinIndex+1, RadarMIC);
	}
}

function Destroyed()
{
	Super.Destroyed();
	
	default.CurrentHelpers.RemoveItem(self);
	
	if( CurrentST != None )
	{
		CurrentST.Render = None;
		CurrentST = None;
		RadarMIC = None;
	}
}

final function byte GetAlphaFromDistance(vector Loc, vector CamLoc)
{
	local float Dist, fZoom;
	local int CutoffDist;
	
	Loc.X = 0;
	Loc.Y = 0;
	CamLoc.X = 0;
	CamLoc.Y = 0;
	
	if( Abs(Loc.Z - CamLoc.Z) > 200.f )
	{
		if( Loc.Z > CamLoc.Z )
			CutoffDist = 400;
		else CutoffDist = 375;
	}
	else return 255;
	
    Dist = VSize(Loc - CamLoc);
    if ( Dist <= 200 )
        fZoom = 1.f;
    else fZoom = FMax(1.f - (Dist - 200) / (CutoffDist - 200), 0.f);

	return Clamp(255 * fZoom, 50, 255);
}

final function RenderRadar(Canvas Canvas)
{
	local rotator KFPCRotation, EnemyRotation;
	local vector EnemyLocation, InstigatorLocation;
	local float PulseWidth, TimeOfDeath, TimeSinceDeath, XL, YL, Sc, OriginalSc, DotSize, DotX, DotY, ArrowSize, RadarDistX, RadarDistY;
	local int Index, ZEDDirection;
	local bool bIsZEDDead;
	local string S;
	local Color ScreenEnemyColor;
	local KFPawn_Monster P;
    local Texture DotTex, ArrowTex;
	local FDeadZed Info;
	local bool bUsingLeftHand;
	local byte ZEDDotAlpha;
	local int RadarDist;
	
	if( Instigator == None )
		return;
	
	InstigatorLocation = Instigator.Location;
	OriginalSc = class'KFGameEngine'.static.GetKFFontScale();
	bUsingLeftHand = WeaponOwner.MySkelMesh.Scale3D.Y < 0;
	
	KFPCRotation.Yaw = WeaponOwner.Rotation.Yaw;
	
	Canvas.SetDrawColor(255, 255, 255, 255);
	Canvas.SetPos(0.f, 0.f);
	Canvas.DrawRotatedTile(ScreenBG, FlippedRot, 512, 512, 0, 0, 512, 512);
	
	RadarDist = WeaponOwner.MaxRadarDistance / 100.f;
	
	Canvas.Font = class'KFGameEngine'.static.GetKFCanvasFont();
	Sc = OriginalSc * 2.f;
	S = RadarDist$"m";
	
	Canvas.TextSize(S, XL, YL, bUsingLeftHand ? -Sc : Sc, Sc);
	
	RadarDistX = (512.f - XL) * 0.5f;
	RadarDistY = 512.f - (YL * 0.25f);
	
	Canvas.SetDrawColor(0, 0, 0, 255);
	Canvas.SetPos(RadarDistX - 1.f, RadarDistY - 1.f);
	Canvas.DrawText(S,, bUsingLeftHand ? -Sc : Sc, -Sc);
	
	Canvas.SetDrawColor(255, 255, 255, 255);
	Canvas.SetPos(RadarDistX, RadarDistY);
	Canvas.DrawText(S,, bUsingLeftHand ? -Sc : Sc, -Sc);
	
	S = int(RadarDist * 0.5f)$"m";
	
	Canvas.TextSize(S, XL, YL, bUsingLeftHand ? -Sc : Sc, Sc);
	
	RadarDistX = (512.f - XL) * 0.5f;
	RadarDistY = (512.f - YL) * 0.5375f;
	
	Canvas.SetDrawColor(0, 0, 0, 255);
	Canvas.SetPos(RadarDistX - 1.f, RadarDistY - 1.f);
	Canvas.DrawText(S,, bUsingLeftHand ? -Sc : Sc, -Sc);
	
	Canvas.SetDrawColor(255, 255, 255, 255);
	Canvas.SetPos(RadarDistX, RadarDistY);
	Canvas.DrawText(S,, bUsingLeftHand ? -Sc : Sc, -Sc);
	
	Sc = OriginalSc * 1.375f;
	S = "Nearest Target\n"$MetersDist$"m";
	
	Canvas.StrLen(S, XL, YL);
	XL *= Sc;
	YL *= Sc;
	
	if( bUsingLeftHand )
		RadarDistX = 64 + XL;
	else RadarDistX = 64;
	RadarDistY = YL + 16;
	
	Canvas.SetDrawColor(0, 0, 0, 255);
	Canvas.SetPos(RadarDistX - 1.f, RadarDistY - 1.f);
	Canvas.DrawText(S,, bUsingLeftHand ? -Sc : Sc, -Sc);
	
	Canvas.SetDrawColor(255, 255, 255, 255);
	Canvas.SetPos(RadarDistX, RadarDistY);
	Canvas.DrawText(S,, bUsingLeftHand ? -Sc : Sc, -Sc);
	
	S = "Horzine\nFirmware 3.0";
	
	Canvas.StrLen(S, XL, YL);
	XL *= Sc;
	YL *= Sc;
	
	if( bUsingLeftHand )
		RadarDistX = 448;
	else RadarDistX = 448 - XL;
	RadarDistY = YL + 16;
	
	Canvas.SetDrawColor(0, 0, 0, 255);
	Canvas.SetPos(RadarDistX - 1.f, RadarDistY - 1.f);
	Canvas.DrawText(S,, bUsingLeftHand ? -Sc : Sc, -Sc);
	
	Canvas.SetDrawColor(255, 255, 255, 255);
	Canvas.SetPos(RadarDistX, RadarDistY);
	Canvas.DrawText(S,, bUsingLeftHand ? -Sc : Sc, -Sc);

	PulseWidth = 1024.f*RadarPulse;
	Canvas.DrawColor.A = 255 - (RadarPulse * 255.f);
	Canvas.SetPos((512.f - PulseWidth) * 0.5f, -256.f);
	Canvas.DrawTile(RingTex, PulseWidth, PulseWidth, 0, 0, RingTex.GetSurfaceWidth(), RingTex.GetSurfaceHeight());
	
	MinEnemyDist = 1.f;
	foreach ZEDCache(P)
    {
		if( P != None )
		{
			bIsZEDDead = !P.IsAliveAndWell();
			if( bIsZEDDead )
			{
				Index = DeadZEDs.Find('P', P);
				if( Index != INDEX_NONE )
				{
					EnemyLocation = DeadZEDs[Index].Location;
					TimeOfDeath = DeadZEDs[Index].TimeOfDeath;
				}
				else
				{
					Info.P = P;
					Info.Location = P.Location;
					Info.TimeOfDeath = WorldInfo.TimeSeconds;
					DeadZEDs.AddItem(Info);
					
					EnemyLocation = Info.Location;
					TimeOfDeath = Info.TimeOfDeath;
				}
				
				TimeSinceDeath = `TimeSince(TimeOfDeath);
				if( TimeSinceDeath > 5.1125f )
					continue;
			}
			else EnemyLocation = P.Location;

			if( EliteZEDCache.Find(P.Class) != INDEX_NONE )
			{
				ScreenEnemyColor = class'HUD'.default.WhiteColor;
				DotTex = bIsZEDDead ? DeathDot : MediumZEDDot;
				DotSize = bIsZEDDead ? 16 : 28;
			}
			else
			{
				if( P.IsABoss() )
				{
					ScreenEnemyColor = class'HUD'.default.RedColor;
					DotTex = bIsZEDDead ? DeathDot : BossDot;
					DotSize = bIsZEDDead ? 32 : 48;
				}
				else
				{
					switch( P.MinSpawnSquadSizeType )
					{
						case EST_Large:
							if( KFPawn_ZedBloat(P) != None )
							{
								ScreenEnemyColor = class'KFHUDBase'.default.YellowColor;
								DotTex = bIsZEDDead ? DeathDot : MediumZEDDot;
								DotSize = bIsZEDDead ? 16 : 32;
							}
							else
							{
								ScreenEnemyColor = class'HUD'.default.RedColor;
								DotTex = bIsZEDDead ? DeathDot : LargeZEDDot;
								DotSize = bIsZEDDead ? 26 : 42;
							}
							break;
						case EST_Medium:
							ScreenEnemyColor = class'KFHUDBase'.default.YellowColor;
							DotTex = bIsZEDDead ? DeathDot : MediumZEDDot;
							DotSize = bIsZEDDead ? 16 : 32;
							break;
						case EST_Crawler:
						case EST_Small:
						default:
							ScreenEnemyColor = class'HUD'.default.WhiteColor;
							DotTex = bIsZEDDead ? DeathDot : SmallZEDDot;
							DotSize = 16;
							break;
					}
				}
			}
			
			ZEDDotAlpha = GetAlphaFromDistance(EnemyLocation, InstigatorLocation);

			EnemyLocation = (EnemyLocation - InstigatorLocation) / WeaponOwner.MaxRadarDistance;

			EnemyRotation.Yaw = rotator(EnemyLocation).Yaw + 16384;

			EnemyLocation.X = VSize2D(EnemyLocation);
			EnemyLocation.Y = 0;
			EnemyLocation.Z = 0;
			
			if( !bIsZEDDead )
			{
				MinEnemyDist = FMin(MinEnemyDist, EnemyLocation.X);
				ScreenEnemyColor.A = ZEDDotAlpha - (ZEDDotAlpha * Abs((EnemyLocation.X*0.00033f) - RadarPulse));
			}
			else ScreenEnemyColor.A = ZEDDotAlpha * (1.f - TimeFraction(TimeOfDeath, TimeOfDeath + 5.1125f, WorldInfo.TimeSeconds));

			EnemyLocation = (EnemyLocation * 496.f) >> (EnemyRotation - KFPCRotation);
			
			if( bUsingLeftHand )
				DotX = 256.f - -EnemyLocation.X - (DotSize * 0.5f);
			else DotX = 256.f - EnemyLocation.X - (DotSize * 0.5f);
			DotY = EnemyLocation.Y - (DotSize * 0.5f);
			
			Canvas.SetDrawColor(0, 0, 0, ScreenEnemyColor.A);
			Canvas.SetPos(DotX + 1, DotY + 1);
			Canvas.DrawRotatedTile(DotTex, FlippedRot, DotSize, DotSize, 0, 0, DotTex.GetSurfaceWidth(), DotTex.GetSurfaceHeight());
			Canvas.DrawColor = ScreenEnemyColor;
			Canvas.SetPos(DotX, DotY);
			Canvas.DrawRotatedTile(DotTex, FlippedRot, DotSize, DotSize, 0, 0, DotTex.GetSurfaceWidth(), DotTex.GetSurfaceHeight());
			
			if( !bIsZEDDead )
			{
				if( Abs(P.Location.Z - InstigatorLocation.Z) > Instigator.CylinderComponent.CollisionHeight )
					ZEDDirection = P.Location.Z > InstigatorLocation.Z ? 1 : -1;
				else ZEDDirection = 0;
					
				if( ZEDDirection != 0 )
				{
					ArrowTex = ZEDDirection == 1 ? ArrowUpTex : ArrowDownTex;
					ArrowSize = DotSize * 0.625f;
					
					DotX = DotX + ((DotSize-ArrowSize) * 0.5f);
					DotY = ZEDDirection == 1 ? DotY + DotSize : DotY - ArrowSize;

					Canvas.SetDrawColor(0, 0, 0, ScreenEnemyColor.A);
					Canvas.SetPos(DotX + 1, DotY + 1);
					Canvas.DrawRotatedTile(ArrowTex, FlippedRot, ArrowSize, ArrowSize, 0, 0, ArrowTex.GetSurfaceWidth(), ArrowTex.GetSurfaceHeight());
					Canvas.DrawColor = ScreenEnemyColor;
					Canvas.SetPos(DotX, DotY);
					Canvas.DrawRotatedTile(ArrowTex, FlippedRot, ArrowSize, ArrowSize, 0, 0, ArrowTex.GetSurfaceWidth(), ArrowTex.GetSurfaceHeight());
				}
			}
		}
    }
	
	Canvas.DrawColor = class'HUD'.default.WhiteColor;
	
	Canvas.DrawColor.A = PulseAlpha - (ScanPulse * PulseAlpha);
	Canvas.SetPos(0.f, (1.f - ScanPulse) * 512.f);
	Canvas.DrawRect(512.f, PulseSize);
	Canvas.DrawColor.A = PulseAlpha2 - (ScanPulse2 * PulseAlpha2);
	Canvas.SetPos(0.f, (1.f - ScanPulse2) * 512.f);
	Canvas.DrawRect(512.f, PulseSize2);
	
	Canvas.DrawColor.A = 255;
	Canvas.SetPos(47.f, 6.f);
	Canvas.DrawTile(ScreenEdgeGlow, 418, 506, 0, 0, 512, 512);
	
	CurrentST.bNeedsUpdate = true;
}

final function float TimeFraction( float Start, float End, float Current )
{
    return FClamp((Current - Start) / (End - Start), 0.f, 1.f);
}

defaultproperties
{
	SmallZEDDot=Texture2D'KFZEDGun_Tex.Low_Zed_Head'
	MediumZEDDot=Texture2D'KFZEDGun_Tex.Zed_Head'
	LargeZEDDot=Texture2D'KFZEDGun_Tex.Zed_Head'
	BossDot=Texture2D'KFZEDGun_Tex.Boss_Zed_Head'
	DeathDot=Texture2D'KFZEDGun_Tex.Dead_Zed_Head'
	ScreenBG=Texture2D'KFZEDGun_Tex.ZED_FX_Screen_BG'
	ScreenEdgeGlow=Texture2D'KFZEDGun_Tex.ZED_FX_Screen_EdgeGlow'
	RingTex=Texture2D'KFZEDGun_Tex.RadarPulse'
	ArrowUpTex=Texture2D'KFZEDGun_Tex.ARROW_UP'
	ArrowDownTex=Texture2D'KFZEDGun_Tex.ARROW_DOWN'
	RadarSkinIndex=1
	FlippedRot=(Pitch=0,Yaw=-32768,Roll=0)
}