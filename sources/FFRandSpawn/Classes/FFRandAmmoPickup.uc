class FFRandAmmoPickup extends KFAmmoPickup;

event PostBeginPlay(){
	// Log("DEBUG: AmmoPickup spawned", self.class.name);
}

auto state Pickup{
	function Touch(Actor Other){
		local Inventory CurInv;
		local bool bPickedUp;
		local int AmmoPickupAmount;
		local Boomstick DBShotty;
		local bool bResuppliedBoomstick;

		if ( Pawn(Other) != none && Pawn(Other).bCanPickupInventory && Pawn(Other).Controller != none && FastTrace(Other.Location, Location) ){
			for ( CurInv = Other.Inventory; CurInv != none; CurInv = CurInv.Inventory ){
				if( Boomstick(CurInv) != none ){
				    DBShotty = Boomstick(CurInv);
				}
                if ( KFAmmunition(CurInv) != none && KFAmmunition(CurInv).bAcceptsAmmoPickups ){
					if ( KFAmmunition(CurInv).AmmoPickupAmount > 0 ){ // Just as PooSH did
						if ( KFAmmunition(CurInv).AmmoAmount < KFAmmunition(CurInv).MaxAmmo ){
							if ( KFPlayerReplicationInfo(Pawn(Other).PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Pawn(Other).PlayerReplicationInfo).ClientVeteranSkill != none ){
								AmmoPickupAmount = float(KFAmmunition(CurInv).AmmoPickupAmount) * KFPlayerReplicationInfo(Pawn(Other).PlayerReplicationInfo).ClientVeteranSkill.static.GetAmmoPickupMod(KFPlayerReplicationInfo(Pawn(Other).PlayerReplicationInfo), KFAmmunition(CurInv));
							} else {
								AmmoPickupAmount = KFAmmunition(CurInv).AmmoPickupAmount;
							}
							KFAmmunition(CurInv).AmmoAmount = Min(KFAmmunition(CurInv).MaxAmmo, KFAmmunition(CurInv).AmmoAmount + AmmoPickupAmount);
							if( DBShotgunAmmo(CurInv) != none ){
                                bResuppliedBoomstick = true;
							}
							bPickedUp = true;
						}
					} else if ( KFAmmunition(CurInv).AmmoAmount < KFAmmunition(CurInv).MaxAmmo ){
						bPickedUp = true;
						if ( FRand() <= (1.0 / Level.Game.GameDifficulty) ){
							KFAmmunition(CurInv).AmmoAmount++;
						}
					}
				}
			}
			if ( bPickedUp ) {
                if( bResuppliedBoomstick && DBShotty != none ){
                    DBShotty.AmmoPickedUp();
                }
                AnnouncePickup(Pawn(Other));
				if ( KFGameType(Level.Game) != none ){
					KFGameType(Level.Game).AmmoPickedUp(self);
				}
				Destroy(); // because I don't want it sticking around
			}
		}
	}
}

state Sleeping{
	ignores Touch;

	function bool ReadyToPickup(float MaxWait){ return false; }
	function StartSleeping() {}
	function BeginState(){}
	function EndState(){}
Begin:
DelayedSpawn:
TryToRespawnAgain:
Respawn:
}

function Reset(){
}

event Landed(Vector HitNormal){
}

defaultproperties
{
	bCollideActors=true
    bCollideWorld=true
	bHidden=false
	DrawType=DT_StaticMesh
	RespawnTime=0.000000
}