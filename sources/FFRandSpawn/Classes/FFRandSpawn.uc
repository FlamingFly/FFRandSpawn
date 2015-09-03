class FFRandSpawn extends KFRandomItemSpawn
	Config(FFRandSpawn);

var() config array<string> SpawnItem;
var array< class<Pickup> > RandClass;
var array<int> RandWeight;

simulated event  postBeginPlay() {
	local string str;
	local int i, index, split, weight;
	local class<Pickup> itemClass;
	
// based on a copy from KFRandomItemSpawn
	if( Level.NetMode!=NM_Client ) {
		if( SpawnItem.Length > 0 ){
			RandClass.Length = 0;
			RandWeight.Length = 0;
			index = 0;
			// Log("Processing ini of length"@SpawnItem.Length, 'FFRandSpawn');
			for( i=0; i<SpawnItem.Length; i++ ) {
				str = SpawnItem[i];
				// Log("Processing ini line"@str, 'FFRandSpawn');
				split = InStr( str, ":" );
				if( split > 0 ) {
					weight = int( Left( str, split ) );
					itemClass = class<Pickup>( DynamicLoadObject( Mid( str, split+1 ), Class'Class' ) );
					if( itemClass != none ){
						RandClass[index] = itemClass;
						RandWeight[index] = weight;
						WeightTotal += weight;
						index++;
					}
				} else {
					Log( "Error ecountered while parsing ini file", 'FFRandSpawn' );
				}
			}
			NumClasses = SpawnItem.Length;
		} else {
			//Log("NOT processing ini of length"@SpawnItem.Length, 'FFRandSpawn');
			NumClasses = RandClass.Length;
		}
		SetPowerUp();
	}
	if ( Level.NetMode != NM_DedicatedServer ) {
		for ( i=0; i< NumClasses; i++ ){
			RandClass[i].static.StaticPrecache(Level);
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
		sum += RandWeight[index];
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
		PowerUp = RandClass[CurrentClass];
	} else {
		PowerUp = none;
	}
}

defaultproperties
{
	RandClass[0]=Class'KFMod.KnifePickup'
	RandWeight[0]=1
}