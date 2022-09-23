// Runner Movement

#include "SpaceshipGlobal.as"
#include "SpaceshipVars.as"

void onInit(CMovement@ this)
{
	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null) return;

	// generic modifiable vars
	SpaceshipVars moveVars;
	moveVars.engineFactor = 1.0f; //multiplier for engine output force
	moveVars.maxSpeedFactor = 1.0f; //multiplier for max speed
	moveVars.turnSpeedFactor = 1.0f; //multiplier for turn speed
	moveVars.dragFactor = 1.0f; //multiplier for drag

	moveVars.firingRateFactor = 1.0f; //lower is higher rate
	moveVars.firingSpreadFactor = 1.0f; //multiplier for bullet spread
	thisBlob.set("moveVars", moveVars);

	// Info and tags
	string thisBlobName = thisBlob.getName();
	int thisBlobHash = thisBlobName.getHash();
	//print ("blobName: "+ thisBlobName +" | blobHash: "+ thisBlobHash);

	bool canBePlayer = false;
	
	u8 shipSize = getShipSize(thisBlobHash);
	thisBlob.set_u8(shipSizeString, shipSize);
	switch(shipSize)
	{
		case _size_small:
		{
			SmallshipInfo ship;

			fetchSmallshipInfo( thisBlobHash, 
			ship.main_engine_force, ship.secondary_engine_force, ship.rcs_force, 
			ship.ship_turn_speed, ship.ship_drag, ship.max_speed, 
			ship.firing_rate, ship.firing_burst, ship.firing_delay, ship.firing_spread, ship.firing_cost, 
			ship.shot_speed, ship.shot_lifetime );

			thisBlob.set("shipInfo", @ship);
			canBePlayer = true;
		}
		break;
		case _size_medium:
		{
			canBePlayer = true;
		}
		break;
		case _size_big:
		{
			canBePlayer = true;
		}
		break;
		case _size_structure:
		{
			
		}
		break;
	}

	if (canBePlayer)
	{
		CShape@ thisShape = thisBlob.getShape();
		if (thisShape != null)
		{
			print ("found shape");
			thisShape.getConsts().net_threshold_multiplier = 0.5f;
		}
		thisBlob.Tag("player");
	}

	thisBlob.Tag("hull");
	thisBlob.Tag("ignore crouch");
}