class FFRandSpawnSettings extends Object
	Config(FFRandSpawn);

// TODO: Ensure pickups

// configurables
var() private config array<string> SpawnItem;
var() private config float PickupCooldown, PickupSpawnInterval, EnsurePickupRatio, EnsureAmmoRatio,
		DespawnChanceRatio, SpawnChanceBeg, SpawnChanceNorm, SpawnChanceHard, SpawnChanceSui, SpawnChanceHoe;
var() private config int AmmoWeight, MinMonsters;
var() private config bool bScaleEnsure;

var private class<FFRandAmmoPickup> AmmoClass;
var private string AmmoClassName;
var private array<FFRandListItem> RandList;
var private int WeightSum;
var private float GameDiff, SpawnChance, DespawnChance, EnsurePickup, EnsureAmmo,
		PickupSpawnIntervalMin, PickupSpawnIntervalMax, PickupCooldownMin, PickupCooldownMax, TurnOffRetryDelay;
var private bool bInitDone, bDiffSet;
// ammo box properties
var private StaticMesh AmmoMesh;
var private float AmmoScale;
var private vector AmmoScale3D;

public event Created (){
	bInitDone = false;
	InitList();
}

private function InitList(){
	local FFRandListItem item;
	local int i;

	if( SpawnItem.Length > 0 ){
		RandList.Length = 0;
		WeightSum = 0;
		// Log("Processing ini of length"@SpawnItem.Length, self.class.name);
		for( i=0; i<SpawnItem.Length; i++ ) {
			item = New class'FFRandListItem';
			if( item.Set( SpawnItem[i] ) && !item.IsA('Ammo')){
				RandList[RandList.Length] = item;
				WeightSum += item.GetWeight();
			} else {
				Log("ERROR: Unable add item to spawn list", self.class.name);
			}
		}
	}
	// add ammo boxes to list
	item = New class'FFRandListItem';
	if( item.Set( ""$AmmoWeight$":"$AmmoClassName ) && class<FFRandAmmoPickup>(item.GetClass()) != none ){
		RandList[RandList.Length] = item;
		WeightSum += item.GetWeight();
		AmmoClass = class<FFRandAmmoPickup>(item.GetClass());
	} else {
		Log("ERROR: Unable to add ammobox to spawn list", self.class.name);
	}
	// validate logic settings
	ValidateRange(PickupSpawnInterval, PickupSpawnIntervalMin, PickupSpawnIntervalMax, "PickupSpawnInterval" );
	ValidateRange(PickupCooldown, PickupCooldownMin, PickupCooldownMax, "PickupCooldown" );
	ValidateRange(EnsurePickupRatio, 0.0, 1.0, "EnsurePickupRatio" );
	ValidateRange(EnsureAmmoRatio, 0.0, 1.0, "EnsureAmmoRatio" );
	ValidateRange(DespawnChanceRatio, 0.0, 0.999999, "DespawnChanceRatio" );
	// validate spawn chances
	ValidateRange(SpawnChanceBeg, 0.0, 1.0, "SpawnChanceBeg" );
	ValidateRange(SpawnChanceNorm, 0.0, 1.0, "SpawnChanceNorm" );
	ValidateRange(SpawnChanceHard, 0.0, 1.0, "SpawnChanceHard" );
	ValidateRange(SpawnChanceSui, 0.0, 1.0, "SpawnChanceSui" );
	ValidateRange(SpawnChanceHoe, 0.0, 1.0, "SpawnChanceHoe" );

	bInitDone = true;
}

private function ValidateRange(out float value, float min, float max, string valName ){
	local float oldValue;
	
	// Log("DEBUG: Validating "$valName$" = "$value, self.class.name);
	oldValue = value;
	value = Fclamp( value, min, max );
	if( value != oldValue ) {
		Log("WARNING: "$valName$" out of range, clamping. (value:"$oldValue$", range:"$min$"-"$max$")", self.class.name);
	}
}

public function class<pickup> GetClass( int index ){
	if( index < RandList.Length ){
		return RandList[index].GetClass();
	} else {
		return none;
	}
}

public function int GetWeight( int index ){
	if( index < RandList.Length ){
		return RandList[index].GetWeight();
	} else {
		return MaxInt;
	}
}

public function int GetClassCount(){
	return RandList.Length;
}

public function int GetWeightSum(){
	return WeightSum;
}

public function SetGameDiff( float diff ){
	local float spawnCh;
	
	GameDiff = diff;
	// pick base spawn chance
	if( diff >= 7.0 ){ // HoE
		spawnCh = SpawnChanceHoe;
	}
	if( diff >= 5.0 && diff < 7.0 ){ // Suicidal
		spawnCh = SpawnChanceSui;
	}
	if( diff >= 4.0 && diff < 5.0 ){ // Hard
		spawnCh = SpawnChanceHard;
	}
	if( diff >= 2.0 && diff < 4.0 ){ // Normal
		spawnCh = SpawnChanceNorm;
	}
	if( diff >= 1.0 && diff < 2.0 ){ // Beginner
		spawnCh = SpawnChanceBeg;
	}
	// scale Ensure* by chance
	if( bScaleEnsure ){
		EnsurePickup = EnsurePickupRatio * spawnCh;
		EnsureAmmo = EnsureAmmoRatio * spawnCh;
	} else {
		EnsurePickup = EnsurePickupRatio;
		EnsureAmmo = EnsureAmmoRatio;
	}
	// calculate SpawnChance
	if( spawnCh >= 0.0 && spawnCh < 1.0 ){
		SpawnChance = (1.0 - Exp(Loge(1.0 - spawnCh)*(PickupSpawnInterval / PickupSpawnIntervalMax)))/(1 - DespawnChanceRatio);
	} else {
		SpawnChance = Fclamp(spawnCh, 0.0, 1.0);
	}
	Log("DEBUG: SpawnChance*10^6 = "$(SpawnChance*1000000), self.class.name);
	DespawnChance = SpawnChance * DespawnChanceRatio;
	Log("DEBUG: DespawnChance*10^6 = "$(DespawnChance*1000000), self.class.name);
	
	bDiffSet = true;
}

public function float GetSpawnChance(){
	return SpawnChance;
}

public function float GetDespawnChance(){
	return DespawnChance;
}

public function SaveAmmoProp( Actor Other ){
	AmmoMesh = Other.StaticMesh;
	AmmoScale = Other.DrawScale;
	AmmoScale3D = Other.DrawScale3D;
}

public function ApplyAmmoProp( Actor Other ){
	Other.SetStaticMesh(AmmoMesh);
	Other.SetDrawScale(AmmoScale);
	Other.SetDrawScale3D(AmmoScale3D);
	Other.SetDrawType(DT_StaticMesh);
}

public function float GetCooldown(){
	return PickupCooldown;
}

public function int GetTurnOffRetryDelay(){
	return TurnOffRetryDelay;
}

public function int GetRefreshInterval(){
	return PickupSpawnInterval;
}

public function class<FFRandAmmoPickup> GetAmmoClass(){
	return AmmoClass;
}

public function bool IsAmmo(class<Pickup> tested){
	return ClassIsChildOf( tested, AmmoClass );
}

public function bool IsReady(){
	return bInitDone && bDiffSet;
}

public function float GetEnsurePickup(){
	return EnsurePickup;
}

public function float GetEnsureAmmo(){
	return EnsureAmmo;
}
public function int GetMinMonsters(){
	return MinMonsters;
}

defaultproperties
{
	SpawnItem="10:KFMod.KnifePickup"
	AmmoWeight=10
	AmmoClassName="FFRandSpawn.FFRandAmmoPickup"
	EnsurePickupRatio=0.0
	EnsureAmmoRatio=0.0
	bScaleEnsure=True
	DespawnChanceRatio=0.5
	MinMonsters=5
	TurnOffRetryDelay=1.0
	PickupCooldown=10.0
	PickupCooldownMin=0.0
	PickupCooldownMax=60.0
	PickupSpawnInterval=15.0
	PickupSpawnIntervalMin=5.0
	PickupSpawnIntervalMax=300.0
	SpawnChanceBeg=1.0
	SpawnChanceNorm=0.66
	SpawnChanceHard=0.44
	SpawnChanceSui=0.3
	SpawnChanceHoe=0.2
}