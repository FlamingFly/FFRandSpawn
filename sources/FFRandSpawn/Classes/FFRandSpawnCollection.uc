class FFRandSpawnCollection extends Object
	Config(FFRandSpawn);

var() config array<string> SpawnItem;
var array< class<Pickup> > RandClass;
var array<int> RandWeight;
var int WeightSum;

event Created (){
	InitList();
}

function InitList(){
	local string str;
	local int i, index, split, weight;
	local class<Pickup> itemClass;

	if( SpawnItem.Length > 0 ){
		RandClass.Length = 0;
		RandWeight.Length = 0;
		WeightSum = 0;
		index = 0;
		// Log("Processing ini of length"@SpawnItem.Length, 'FFRandSpawnCollection');
		for( i=0; i<SpawnItem.Length; i++ ) {
			str = SpawnItem[i];
			// Log("Processing ini line"@str, 'FFRandSpawnCollection');
			split = InStr( str, ":" );
			if( split > 0 ) {
				weight = int( Left( str, split ) );
				itemClass = class<Pickup>( DynamicLoadObject( Mid( str, split+1 ), Class'Class' ) );
				if( itemClass != none ){
					RandClass[index] = itemClass;
					RandWeight[index] = weight;
					WeightSum += weight;
					index++;
				}
			} else {
				// Log( "Error ecountered while parsing ini file", 'FFRandSpawnCollection' );
			}
		}
	} else {
		// Log("NOT processing ini of length"@SpawnItem.Length, 'FFRandSpawnCollection');
	}
}

function class<pickup> GetClass( int ClassIndex ){
	if( ClassIndex < RandClass.Length ){
		return RandClass[ClassIndex];
	} else {
		return none;
	}
}

function int GetWeight( int ClassIndex ){
	if( ClassIndex < RandWeight.Length ){
		return RandWeight[ClassIndex];
	} else {
		return MaxInt;
	}
}

function int GetClassCount(){
	return RandClass.Length;
}

function int GetWeightSum(){
	return WeightSum;
}

defaultproperties
{
	RandClass[0]=Class'KFMod.KnifePickup'
	RandWeight[0]=100
	WeightSum=100
}