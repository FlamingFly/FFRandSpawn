class FFRandListItem extends Object;

var private class<Pickup> ItemClass;
var private int ItemRandWeight;
var private bool bIsSet;

public function Created(){
	bIsSet = false;
}

public function bool Set( string item ){
	local int split;

	if( !bIsSet ){
		split = InStr( item, ":" );
		if( split > 0 ) {
			ItemRandWeight = int( Left( item, split ) );
			ItemClass = class<Pickup>( DynamicLoadObject( Mid( item, split+1 ), Class'Class' ) );
			if( ItemClass != none && ItemRandWeight > 0){
				bIsSet = true;
				return true;
			}
		}
		Log("Unable to process line: >"$item$"<", self.class.name);
		return false;
	} else {
		Log("Attempt to reset Item properties", self.class.name);
		return false;
	}
}

public function int GetWeight(){
	return ItemRandWeight;
}

public function class<Pickup> GetClass(){
	return ItemClass;
}