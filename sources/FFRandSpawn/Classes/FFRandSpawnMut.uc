class FFRandSpawnMut extends Mutator;

var FFRandSpawnCollection RSC;

simulated event PostBeginPlay(){
	RSC = New class'FFRandSpawnCollection';
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant){
	if( Other.class == class'KFRandomItemSpawn' || Other.class == class'ScrnRandomItemSpawn' ){
		ReplaceWith(Other, "FFRandSpawn.FFRandSpawn");
		return false;
	}
	// if ( Other.class == class'KFAmmoPickup' || Other.class == class'ScrnAmmoPickup' ){
		// ReplaceWith(Other, "FFRandSpawn.FFRandSpawn");
		// return false;
	// }
	if( Other.class == class'FFRandSpawn' ){
		FFRandSpawn(Other).RSC = RSC;
		return true;
	}
	return true;
}

defaultproperties
{
	GroupName="KF_FFRandSpawn"
	FriendlyName="FF Random Spawn"
	Description="Configurable (ini) replacement for random item spawns"
}