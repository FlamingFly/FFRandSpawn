class FFRandFakeAmmoSpawn extends KFAmmoPickup;

event PostBeginPlay(){
	// Log("DEBUG: FakeAmmo spawned", self.class.name);
}

event Landed(Vector HitNormal){}
function float GetNumPlayers(){ return 1.0; }
function float BotDesireability(Pawn Bot){ return 0; }
function Reset(){}

state Pickup{
	ignores Touch;
	function Touch(Actor Other){}
}

auto state Sleeping{
	ignores Touch;
	function bool ReadyToPickup(float MaxWait){ return false; }
	function StartSleeping(){}
	function BeginState(){}
	function EndState(){}
Begin:
DelayedSpawn:
TryToRespawnAgain:
Respawn:
}

defaultproperties
{
	RespawnTime=0.000000
	DrawType=DT_None
	Physics=PHYS_None
	bCollideActors=False
	bCollideWorld=False
	bHidden=True
}