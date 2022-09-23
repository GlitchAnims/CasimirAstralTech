// Runner Movement

#include "SpaceshipGlobal.as"
#include "SpaceshipVars.as"
#include "PodCommon.as"

void onInit(CMovement@ this)
{
	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null) return;

	CShape@ thisShape = thisBlob.getShape();
	const bool foundShape = thisShape != null;

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
	bool rotationsAllowed = false;
	
	u8 shipSize = getShipSize(thisBlobHash);
	thisBlob.set_u8(shipSizeString, shipSize);
	switch(shipSize)
	{
		case _size_box:
		{
			PodInfo pod;
			fetchPodInfo(thisBlobHash, pod.carry_can_turn, pod.carry_turn_speed, pod.carry_vel, pod.carry_dist);
			thisBlob.set("podInfo", @pod);

			if (foundShape) thisShape.SetRotationsAllowed(pod.carry_can_turn);
		}
		break;

		case _size_small:
		{
			SmallshipInfo ship;

			fetchSmallshipInfo( thisBlobHash, 
			ship.main_engine_force, ship.secondary_engine_force, ship.rcs_force, 
			ship.ship_turn_speed, ship.ship_drag, ship.max_speed, 
			ship.firing_rate, ship.firing_burst, ship.firing_delay, ship.firing_spread, ship.firing_cost, 
			ship.shot_speed, ship.shot_lifetime );

			thisBlob.set("shipInfo", @ship);
			rotationsAllowed = false;
			canBePlayer = true;
		}
		break;

		case _size_medium:
		{
			rotationsAllowed = true;
			canBePlayer = true;
		}
		break;

		case _size_big:
		{
			rotationsAllowed = false;
			canBePlayer = true;
		}
		break;

		case _size_structure:
		{
			rotationsAllowed = false;
		}
		break;

		default:
		{
			print("ship size not found: "+ thisBlobName +" | hash: "+ thisBlobHash);
		}
		break;
	}
	

	if (canBePlayer)
	{
		if (foundShape)
		{
			thisShape.getConsts().net_threshold_multiplier = 0.5f;
		}
		thisBlob.Tag("player");
	}
	if (foundShape)
	{
		thisShape.SetRotationsAllowed(rotationsAllowed);
	}
	

	thisBlob.Tag("hull");
	thisBlob.Tag("ignore crouch");
}