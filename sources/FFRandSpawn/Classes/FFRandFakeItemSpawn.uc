class FFRandFakeItemSpawn extends KFRandomItemSpawn;

event PostBeginPlay(){
	// Log("DEBUG: FakeItem spawned", self.class.name);
}

function SpawnPickup(){}
function NotifyNewWave(int CurrentWave, int FinalWave){}
function EnableMe(){}
function EnableMeDelayed(float Delay){}
function int GetWeightedRandClass(){ return 1; }
function TurnOn(){}
function timer(){}
function bool PlayersCanSeeMe(){ return false; }
function bool RandomEnabled( int CurrentWave, int FinalWave ){ return false; }
function DisableMe(){}

defaultproperties
{
	bIsEnabledNow=False
	DrawType=DT_None
	Physics=PHYS_None
	bCollideActors=False
	bCollideWorld=False
	bHidden=True
}