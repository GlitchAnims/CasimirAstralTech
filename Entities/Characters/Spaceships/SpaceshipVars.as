// Runner Common

shared class SpaceshipVars
{
	f32 engineFactor = 1.0f; //multiplier for engine output force
	f32 maxSpeedFactor = 1.0f; //multiplier for max speed
	f32 turnSpeedFactor = 1.0f; //multiplier for turn speed
	f32 dragFactor = 1.0f; //multiplier for drag

	f32 firingRateFactor = 1.0f; //lower is higher rate
	f32 firingSpreadFactor = 1.0f; //multiplier for bullet spread

	bool is_warp = false;
	bool is_boost = false;

	bool forward_thrust = false;
	bool backward_thrust = false;
	bool port_thrust = false;
	bool portBow_thrust = false;
	bool portQuarter_thrust = false;
	bool starboard_thrust = false;
	bool starboardBow_thrust = false;
	bool starboardQuarter_thrust = false;
};

//cleanup all vars here - reset clean slate for next frame
void CleanUp(CMovement@ this, CBlob@ thisBlob, SpaceshipVars@ moveVars)
{
	//reset all the vars here
	moveVars.engineFactor = 1.0f;
	moveVars.maxSpeedFactor = 1.0f;
	moveVars.turnSpeedFactor = 1.0f;
    moveVars.dragFactor = 1.0f;

    moveVars.firingRateFactor = 1.0f;
    moveVars.firingSpreadFactor = 1.0f;
}