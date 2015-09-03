class FFRandSpawnMut extends Mutator;

function bool CheckReplacement(Actor Other, out byte bSuperRelevant){

	if ( Other.class == class'KFRandomItemSpawn' || Other.class == class'ScrnRandomItemSpawn' ) {
		ReplaceWith(Other, "FFRandSpawn.FFRandSpawn");
		//Log("Replaced" @ string(Other), 'FFRandSpawnMut');
		return false;
	}
	// if ( Other.class == class'KFAmmoPickup' || Other.class == class'ScrnAmmoPickup' ) {
		// ReplaceWith(Other, "FFRandSpawn.FFRandSpawn");
		// return false;
	// }
	return true;
}

defaultproperties
{
	GroupName="KF_FFRandSpawn"
	FriendlyName="FF Random Spawn "
	Description="Configurable replacement for random item spawns"
}