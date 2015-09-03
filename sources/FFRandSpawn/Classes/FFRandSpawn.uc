class FFRandSpawn extends KFRandomItemSpawn;

var FFRandSpawnCollection RSC;

simulated event PostBeginPlay() {
	local int i;
	
// based on a copy from KFRandomItemSpawn
	if( Level.NetMode!=NM_Client ) {
		NumClasses = RSC.GetClassCount();
		WeightTotal = RSC.GetWeightSum();
		SetPowerUp();
	}
	if ( Level.NetMode != NM_DedicatedServer ) {
		for ( i=0; i< NumClasses; i++ ){
			RSC.GetClass(i).static.StaticPrecache(Level);
		}
	}
	if ( KFGameType(Level.Game) != none ) {
		KFGameType(Level.Game).WeaponPickups[KFGameType(Level.Game).WeaponPickups.Length] = self;
		DisableMe();
	}
	//SetLocation(Location - vect(0,0,1)); // necessary?
}

function int GetWeightedRandClass(){
	local int rnd, sum, index;

	rnd = rand(WeightTotal+1);
	sum = 0;
	index = -1;
	while(sum<rnd){
		index += 1;
		sum += RSC.GetWeight(index);
	}
	return index;
}

function TurnOn(){
	SetPowerUp();
	if( myPickup != none ) {
		myPickup.Destroy();
	}
	SpawnPickup();
	SetTimer(InitialWaitTime+InitialWaitTime*FRand(), false);
}

function SetPowerUp(){
	CurrentClass=GetWeightedRandClass();
	if( CurrentClass >= 0 ){
		PowerUp = RSC.GetClass(CurrentClass);
	} else {
		PowerUp = none;
	}
}

defaultproperties
{
}