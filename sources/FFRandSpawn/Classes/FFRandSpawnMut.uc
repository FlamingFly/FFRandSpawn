class FFRandSpawnMut extends Mutator;

const VERSION = "1.002";

var private FFRandSpawnSettings Settings;
var private bool bAmmoSet, bTimerSet, bWaitForSettings;
var private array<FFRandItemSpawn> AllSpawners, ActiveSpawners, ActiveItemSpawners, ActiveAmmoSpawners, ReadySpawners, CoolingSpawners;
var private KFGameType Game;
var private FFRandFakeAmmoSpawn FakeAmmo;
var private FFRandFakeItemSpawn FakeItem;

simulated event PostBeginPlay(){
	Log("Info: FFRandSpawn starting ...", self.class.name);
	if( Level.Game.IsA('KFGameType')) {
        Game = KFGameType(Level.Game);
    } else {
        Log("ERROR: This mutator is only compatible with KFGameType and derivatives", self.class.name);
        Destroy();
		return;
	}
	bWaitForSettings = true;
	Settings = New class'FFRandSpawnSettings';
	Settings.SetGameDiff(Game.GameDifficulty);
	bWaitForSettings = !Settings.IsReady();
	bAmmoSet = false;
	bTimerSet = false;
	SetTimer(0.5, true);
	// spawn and register fake actors to put something into KFGameType's lists
	FakeAmmo = Spawn( class'FFRandFakeAmmoSpawn', self,, Vect(0,0,0),);
	FakeItem = Spawn( class'FFRandFakeItemSpawn', self,, Vect(0,0,0),);
	ApplyFakes();
	Log("Info: FFRandSpawn started. Version:"$VERSION, self.class.name);
}

public function bool CheckReplacement(Actor Other, out byte bSuperRelevant){
	// Log("DEBUG: CheckReplacement()", self.class.name);
	if( Other.IsA('KFRandomItemSpawn') ){
		// Log("DEBUG: Checking random item spawn", self.class.name);
		if( Other.class == class'FFRandItemSpawn' ){
			// Log("DEBUG: FFRandItemSpawn OK", self.class.name);
			FFRandItemSpawn(Other).Setup(Settings, self);
			// Log("DEBUG: Adding spawner to lists", self.class.name);
			AddSpawnerToList( FFRandItemSpawn(Other), AllSpawners );
			return true;
		} else if( Other.class == class'FFRandFakeItemSpawn' ){
			// Log("DEBUG: FFRandFakeItemSpawn OK", self.class.name);
			return true;
		} else {
			// Log("DEBUG: replacing random item spawn", self.class.name);
			ReplaceWith(Other, "FFRandSpawn.FFRandItemSpawn");
			return false;
		}
	}
	if ( Other.IsA('KFAmmoPickup') ){
		// Log("DEBUG: Checking AmmoBox actor", self.class.name);
		if( !bAmmoSet && !Other.IsA('FFRandAmmoPickup') && !Other.IsA('FFRandFakeAmmoSpawn')){
			// Log("DEBUG: Capturing AmmoBox properties", self.class.name);
			Settings.SaveAmmoProp(Other);
			bAmmoSet = true;
		}
		if( Other.class == class'FFRandAmmoPickup' ){
			// Log("DEBUG: Owner OK, replacing visuals", self.class.name);
			Settings.ApplyAmmoProp(Other);
			return true;
		} else if( Other.class == class'FFRandFakeAmmoSpawn' ){
			// Log("DEBUG: FFRandFakeAmmoSpawn OK", self.class.name);
			return true;
		} else {
			// Log("DEBUG: Replacing AmmoBox", self.class.name);
			ReplaceWith(Other, "FFRandSpawn.FFRandItemSpawn");
			return false;
		}
	}
	return true;
}

public function Timer(){
	// Log("DEBUG: Timer()", self.class.name);
	if( bWaitForSettings ){
		Log("DEBUG: Waiting for settings to initialize", self.class.name);
		bWaitForSettings = !Settings.IsReady();
	} else if( Game.IsInState('MatchInProgress') ){
		if( !bTimerSet ){
			SetTimer(-1.0, false);
			SetTimer(Settings.GetRefreshInterval(), true);
			bTimerSet = true;
		} 
		RefreshPickups();
	}
	if( Game.WeaponPickups.Length > 1 || Game.AmmoPickups.Length > 1 ){
		ApplyFakes();
	}
}

private function RefreshPickups(){
	// only spawn new pickups when trader is closed and
	// there are more than MinMonsters left on the map
	// or there are Zeds left to spawn.
	// Otherwise nothing new will spawn but despawn
	// keeps running.
	local int i;
	local float chance;
	local array<FFRandItemSpawn> tmpList;

	// Log("DEBUG: RefreshPickups()", self.class.name);
	// first, pick some Spawners to turn off
	// this is processed all the time while the match is in progress
	chance = Settings.GetDespawnChance();
	// Log("DEBUG: DespawnChance = "$chance, self.class.name);
	for( i=0; i < ActiveSpawners.Length; i++ ){
		if( Frand() < chance ){
			AddSpawnerToList( ActiveSpawners[i], tmpList );
		}
	}
	for( i=0; i < tmpList.Length; i++ ){
		tmpList[i].TurnOff();
	}
	// clear the work list
	tmpList.Length = 0;
	// then pick Spawners to spawn new random items
	if( !Game.bTradingDoorsOpen && ( Game.NumMonsters > Settings.GetMinMonsters() || Game.TotalMaxMonsters > 0 ) ){
		chance = Settings.GetSpawnChance();
		// Log("DEBUG: SpawnChance = "$chance, self.class.name);
		for( i=0; i < ReadySpawners.Length; i++ ){
			if( Frand() < chance ){
				AddSpawnerToList( ReadySpawners[i], tmpList );
			}
		}
		for( i=0; i < tmpList.Length; i++ ){
			tmpList[i].SpawnRandom();
		}
	}
	EnsurePickups();
}

public function NotifyOnPickupTaken( FFRandItemSpawn Spawner ){
	// Log("DEBUG: NotifyOnPickupTaken()", self.class.name);
	if( Spawner.IsAmmo() ){
		RemoveSpawnerFromList( Spawner, ActiveAmmoSpawners );
	} else {
		RemoveSpawnerFromList( Spawner, ActiveItemSpawners );
	}
	RemoveSpawnerFromList( Spawner, ActiveSpawners );
	AddSpawnerToList( Spawner, CoolingSpawners );
	EnsurePickups();
}

public function NotifyOnPickupSpawned( FFRandItemSpawn Spawner ){
	// Log("DEBUG: NotifyOnPickupSpawned()", self.class.name);
	RemoveSpawnerFromList( Spawner, CoolingSpawners );
	RemoveSpawnerFromList( Spawner, ReadySpawners );
	if( Spawner.IsAmmo() ){
		AddSpawnerToList( Spawner, ActiveAmmoSpawners );
	} else {
		AddSpawnerToList( Spawner, ActiveItemSpawners );
	}
	AddSpawnerToList( Spawner, ActiveSpawners );
}

public function NotifyOnReady( FFRandItemSpawn Spawner ){
	// Log("DEBUG: NotifyOnReady()", self.class.name);
	RemoveSpawnerFromList( Spawner, CoolingSpawners );
	AddSpawnerToList( Spawner, ReadySpawners );
}

public function NotifyOnTurnOff( FFRandItemSpawn Spawner ){
	// Log("DEBUG: NotifyOnTurnOff()", self.class.name);
	if( Spawner.IsAmmo() ){
		RemoveSpawnerFromList( Spawner, ActiveAmmoSpawners );
	} else {
		RemoveSpawnerFromList( Spawner, ActiveItemSpawners );
	}
	RemoveSpawnerFromList( Spawner, ActiveSpawners );
	AddSpawnerToList( Spawner, ReadySpawners );
	EnsurePickups();
}

private function EnsurePickups(){
	local int i, missing;
	local float calc;
	local FFRandItemSpawn spawner;
	
	// Log("DEBUG: EnsurePickups()", self.class.name);
	// calculate pickups to fill in the ensured number and spawn new pickups
	// from ready or cooling spawners if ran out of the first
	calc = float(AllSpawners.Length) * Settings.GetEnsurePickup() - ActiveSpawners.Length;
	// Log("DEBUG: calc = "$calc, self.class.name);
	// poor man's Floor();
	missing = int(calc);
	// Log("DEBUG: missing = "$missing, self.class.name);
	if( missing > 0 ){
		for( i=0; i < missing; i++ ){
			if( ReadySpawners.Length > 0 ){
				ReadySpawners[Rand( ReadySpawners.Length )].SpawnRandom();
			} else if( CoolingSpawners.Length > 0 ){
				CoolingSpawners[Rand( CoolingSpawners.Length )].SpawnRandom( true ); // force the spawn
			} else {
				Log("WARNING: Ran out of available spawners while ensuring required pickup spawns", self.class.name);
				return;
			}
		}
	}
	// do the same for ammo pickups
	calc = float(ActiveSpawners.Length) * Settings.GetEnsureAmmo() - ActiveAmmoSpawners.Length;
	// Log("DEBUG: calc = "$calc, self.class.name);
	missing = int(calc);
	// Log("DEBUG: missing = "$missing, self.class.name);
	if( missing > 0 ){
		for( i=0; i < missing; i++ ){
			if( ActiveItemSpawners.Length > 0 ){
				spawner = ActiveItemSpawners[Rand( ActiveItemSpawners.Length )];
				spawner.TurnOff( true ); // force removal
				spawner.SpawnSpecific( Settings.GetAmmoClass(), true ); // force spawn
			} else {
				Log("ERROR: No spawners to change to ammo while more than zero changes required", self.class.name);
				return;
			}
		}
	}
}

private function RemoveSpawnerFromList( FFRandItemSpawn Spawner, out array<FFRandItemSpawn> List ){
	local int i;
	
	for(i=0; i<List.Length; i++){
		if( List[i] == Spawner){
			List.Remove(i, 1);
			break;
		}
	}
}

private function AddSpawnerToList( FFRandItemSpawn Spawner, out array<FFRandItemSpawn> List ){
	local int i;
	
	for(i=0; i<List.Length; i++){
		if( List[i] == Spawner){
			return; // avoid duplicate entries
		}
	}
	List[List.Length] = Spawner;
}

private function ApplyFakes(){
	// Log("DEBUG: ApplyFakes()", self.class.name);
	Game.WeaponPickups.Length = 0;
	Game.WeaponPickups[0] = FakeItem;
	Game.AmmoPickups.Length = 0;
	Game.AmmoPickups[0] = FakeAmmo;
}

defaultproperties
{
	GroupName="KF_FlamingFly"
	FriendlyName="FF Random Spawn"
	Description="Configurable (ini) replacement for random item spawns"
	bAddToServerPackages=True
}