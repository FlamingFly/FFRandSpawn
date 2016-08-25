class FFRandItemSpawn extends KFRandomItemSpawn;

var private FFRandSpawnSettings Settings;
var private FFRandSpawnMut myMut;
var private bool bDelayedOff, bTurningOff, bWaitForSettings;
var private float RandomPosRange, TurnOffRetryTime, CooldownEndTime;
var private int MaxSpawnRetry;


simulated public event PostBeginPlay(){
	// local int i;
	// Log("DEBUG: PostBeginPlay()", self.class.name);
	// for timeimg checks
	bTurningOff = false;
	bWaitForSettings = true;
	SetTimer(1, true);
	// if ( Level.NetMode != NM_DedicatedServer ) {
		// for ( i=0; i< Settings.GetClassCount(); i++ ){
			// Settings.GetClass(i).static.StaticPrecache(Level);
		// }
	// }
}

public function bool IsAmmo(){
	return ( myPickup != none && Settings.IsAmmo( myPickup.class ) );
}

public function bool TurnOff(optional bool force){
	// Log("DEBUG: TurnOff()", self.class.name);
	if( myPickup != none ){
		if( force || !myPickup.PlayerCanSeeMe() ){
			// noone can see the pickup (spawner is hidden, so need to check against pickup)
			bTurningOff = true;
			myPickup.Destroy();
			TurnOffRetryTime = 0;
			return true;
		} else {
			// the pickup is being seen, schedule retry
			bDelayedOff = true;
			TurnOffRetryTime = Level.TimeSeconds + Settings.GetTurnOffRetryDelay();
			return false;
		}
	}
}

public function LostChild( Actor lost ){
	// Log("DEBUG: LostChild()", self.class.name);
	if( lost == myPickup ){
		if( bTurningOff ){
			myMut.NotifyOnTurnOff( self );
			bTurningOff = False;
		} else {
			myMut.NotifyOnPickupTaken( self );
			CooldownEndTime = Level.TimeSeconds + Settings.GetCooldown();
		}
	}
}

public function SpawnRandom(optional bool force){
	local int rnd, sum, index/*, i, weight */;

	if(force || CanSpawn()){
		// pick a new class to spawn
		rnd = 1 + rand(Settings.GetWeightSum());
		sum = 0;
		index = -1;
		while(sum<rnd){
			index += 1;
			sum += Settings.GetWeight(index);
		}
		// if no errors, spawn
		if( index >= 0 ){
			SpawnItem(Settings.GetClass(index), force);
		} else {
			Log("DEBUG: Failed to generate spawn", self.class.name);
		}
	} else {
		Log("ERROR: Tried to spawn while on cooldown or still active", self.class.name);
	}
}

public function SpawnSpecific( class<Pickup> itemClass, optional bool force){
	if(force || CanSpawn()){
		SpawnItem( itemClass, force );
	} else {
		Log("ERROR: Tried to spawn while on cooldown or still active", self.class.name);
	}
}

private function SpawnItem( class<Pickup> itemClass, bool force ){
	local vector rndPos;
	local rotator rndRot;
	local int i;

	// Log("DEBUG: SpawnItem() Spawning: "$itemClass, self.class.name);
	// prepare random rotation
	rndRot = rot(0,0,0);
	rndRot.Yaw = Rand(65536);
	// prepare random position offset
	rndPos = vect(0,0,0);
	rndPos.X = Frand();
	rndPos.Y = Frand();
	rndPos = Normal(rndPos) * RandomPosRange * Frand();
	// if forced and there is a pickup, remove it
	if( force && myPickup != none ){
		myPickup.Destroy();
	}
	if(myPickup == none){
		// try to spawn at the random location and halve it if failed until spawned or ran out of attempts
		for( i=0; ( myPickup == none && i < MaxSpawnRetry && VSize(rndPos) < 1.0 ); i++){
			myPickUp = Spawn( itemClass, self,, (self.Location + rndPos + (vect(0,0,1) * SpawnHeight)), rndRot);
			rndPos = rndPos * 0.5;
		}
		// if above failed to spawn pickup, then spawn it directly above self
		if( myPickup == none ){
			myPickUp = Spawn( itemClass, self,, (self.Location + (vect(0,0,1) * SpawnHeight)), rndRot);
		}
		// set the pickup's properties
		if( myPickUp != none ) {
			// Log("DEBUG: Spawned", self.class.name);
			myPickUp.PickUpBase = self;
			myPickup.RespawnTime = 0;
			myPickup.SetPhysics(PHYS_Falling);
			CooldownEndTime = -1;
			myMut.NotifyOnPickupSpawned( self );
		} else {
			Log("WARNING: Failed to spawn "$itemClass$" on position "$(self.Location + (vect(0,0,1) * SpawnHeight)), self.class.name);
		}
	} else {
		Log("WARNING: Not spawning new pickup, already have one.", self.class.name);
	}
}

public function bool CanSpawn(){
	return ( myPickup == none && Level.TimeSeconds >= CooldownEndTime );
}

public function Timer(){
	if( bDelayedOff && Level.TimeSeconds >= TurnOffRetryTime){
		TurnOff();
	}
	if( CooldownEndTime > -1 && Level.TimeSeconds >= CooldownEndTime ){
		CooldownEndTime = -1;
		myMut.NotifyOnReady( self );
	}
	if( bWaitForSettings && Settings.IsReady() ){
		myMut.NotifyOnReady( self );
		bWaitForSettings = false;
		RandomPosRange = Settings.GetMaxRandRange();
	}
}

public function Setup(FFRandSpawnSettings S, FFRandSpawnMut M){
	Settings = S;
	myMut = M;
}

public function EnableMe(){}

public function DisableMe(){}

public function TurnOn(){}

public function SpawnPickup(){}

defaultproperties
{
	CooldownEndTime=-1
	SpawnHeight=50.0
	RandomPosRange=50.0
	MaxSpawnRetry=10
	bIsEnabledNow=True
}