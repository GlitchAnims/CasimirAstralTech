// Fighter Movement

#include "MediumshipCommon.as"
#include "ChargeCommon.as"
#include "SpaceshipVars.as"
#include "MakeDustParticle.as";
#include "KnockedCommon.as";
#include "CommonFX.as"

void onInit(CMovement@ this)
{
	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null)
	{ return; }

	thisBlob.set_u32("accelSoundDelay",0);

	this.getCurrentScript().removeIfTag = "dead";

	//thisBlob.set_s32("rightTap",0);
	//thisBlob.set_s32("leftTap",0);
	//thisBlob.set_s32("upTap",0);
	//thisBlob.set_s32("downTap",0);

	thisBlob.set_u32( "m3_heldTime", 0 );
	thisBlob.set_u32( "m3_cooldown", 0 );

	thisBlob.set_bool("movementFirstTick", true);
	thisBlob.set_bool(isWarpBoolString, false); // SpaceshipGlobal.as

	if (isServer())
	{
		CAttachment@ attachments = thisBlob.getAttachments();
		if (attachments == null)
		{ return; }

		Vec2f ownerPos = thisBlob.getPosition();

		AttachmentPoint@ slot1 = attachments.getAttachmentPointByName("ENGINESLOT1");
		AttachmentPoint@ slot2 = attachments.getAttachmentPointByName("ENGINESLOT2");

		if (slot1 != null)
		{
			Vec2f slotOffset = slot1.offset;
			CBlob@ turret = slot1.getOccupied();
			if (turret == null)
			{
				CBlob@ blob = server_CreateBlob( "engine_blob" , -1, ownerPos + slotOffset);
				if (blob !is null)
				{
					blob.IgnoreCollisionWhileOverlapped( thisBlob );
					thisBlob.server_AttachTo(blob, slot1);
					blob.set_u32("ownerBlobID", thisBlob.getNetworkID());
					blob.set_u8("soundemit_num", 1);
				}
			}
		}
		if (slot2 != null)
		{
			Vec2f slotOffset = slot2.offset;
			CBlob@ turret = slot2.getOccupied();
			if (turret == null)
			{
				CBlob@ blob = server_CreateBlob( "engine_blob" , -1, ownerPos + slotOffset);
				if (blob !is null)
				{
					blob.IgnoreCollisionWhileOverlapped( thisBlob );
					thisBlob.server_AttachTo(blob, slot2);
					blob.set_u32("ownerBlobID", thisBlob.getNetworkID());
					blob.set_u8("soundemit_num", 2);
				}
			}
		}
	}
}

void onTick(CMovement@ this)
{
	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null)
	{ return; }

	if (thisBlob.get_bool("movementFirstTick"))
	{
		if (thisBlob.getTeamNum() == 1)
		{
			thisBlob.setAngleDegrees(270);
		}
		else
		{
			thisBlob.setAngleDegrees(90);
		}
		thisBlob.set_bool("movementFirstTick", false);
	}

	CShape@ shape = thisBlob.getShape();
	CSprite@ sprite = thisBlob.getSprite();

	CMap@ map = getMap(); //standard map check
	if (map is null)
	{ return; }

	SpaceshipVars@ moveVars;
	if (!thisBlob.get("moveVars", @moveVars))
	{ return; }

	MediumshipInfo@ ship;
	if (!thisBlob.get( "shipInfo", @ship )) 
	{ return; }
	
	const bool left		= thisBlob.isKeyPressed(key_left);
	const bool right	= thisBlob.isKeyPressed(key_right);
	const bool up		= thisBlob.isKeyPressed(key_up);
	const bool down		= thisBlob.isKeyPressed(key_down);

	const bool isShifting = thisBlob.get_bool("shifting");
	const bool isWheelButton = thisBlob.get_bool("wheel_button");
	
	bool[] allKeys =
	{
		up,
		down,
		left,
		right
	};

	u8 keysPressedAmount = 0;
	for (uint i = 0; i < allKeys.length; i ++)
	{
		bool currentKey = allKeys[i];
		if (currentKey)
		{ keysPressedAmount++; }
	}
	
	const bool isknocked = isKnocked(thisBlob) || (thisBlob.get_bool("frozen") == true);
	const bool is_client = isClient();

	Vec2f thisPos = thisBlob.getPosition();
	Vec2f thisVel = thisBlob.getVelocity();
	Vec2f oldVel = thisVel;
	
	f32 blobAngle = thisBlob.getAngleDegrees();
	blobAngle = Maths::Abs(blobAngle) % 360;

	if (blobAngle > 180 && !thisBlob.isFacingLeft()) //flips ship if aiming left
	{
		thisBlob.SetFacingLeft(true);
	}
	else if (blobAngle <= 180 && thisBlob.isFacingLeft())
	{
		thisBlob.SetFacingLeft(false);
	}

	checkWarp( thisBlob, isWheelButton, thisPos, thisVel, blobAngle, ship, moveVars, is_client); // engage warp speed :)

	if (shape != null)
	{
		f32 gravScale = 0.0f;
		if (shape.getGravityScale() != gravScale)
		{
			shape.SetGravityScale(0.0f);
		}
		
		f32 dragScale = ship.ship_drag * moveVars.dragFactor;
		if (shape.getDrag() != dragScale)
		{
			shape.setDrag(dragScale);
		}
	}

	const f32 vellen = shape.vellen;
	const bool onground = thisBlob.isOnGround() || thisBlob.isOnLadder();
	const bool facingLeft = thisBlob.isFacingLeft();

	f32 blobSpinVel = thisBlob.getAngularVelocity();
	f32 oldSpinVel = blobSpinVel;
	
	if (keysPressedAmount != 0 && !thisBlob.isAttached())
	{
		Vec2f forward		= Vec2f_zero;
		Vec2f backward		= Vec2f_zero;
		Vec2f port			= Vec2f_zero;
		Vec2f starboard		= Vec2f_zero;
		float addedSpin 	= 0.0f;

		if(up)
		{
			Vec2f thrustVel = Vec2f(0, -ship.main_engine_force);
			//thrustVel.RotateByDegrees(blobAngle);
			forward += thrustVel;
			ship.forward_thrust = true;
		}
		else
		{ ship.forward_thrust = false; }

		if(down)
		{
			Vec2f thrustVel = Vec2f(0, ship.secondary_engine_force);
			//thrustVel.RotateByDegrees(blobAngle);
			backward += thrustVel;
			ship.backward_thrust = true;
		}
		else
		{ ship.backward_thrust = false; }

		if (isShifting)
		{
			ship.portBow_thrust = false;
			ship.portQuarter_thrust = false;
			ship.starboardBow_thrust = false;
			ship.starboardQuarter_thrust = false;

			if(left)
			{
				Vec2f thrustVel = Vec2f(-ship.rcs_force, 0);
				//thrustVel.RotateByDegrees(blobAngle);
				port += thrustVel;

				if (facingLeft)
				{ ship.port_thrust = true; }
				else
				{ ship.starboard_thrust = true; }
			}
			else
			{
				if (facingLeft)
				{ ship.port_thrust = false; }
				else
				{ ship.starboard_thrust = false; }
			}
			
			if(right)
			{
				Vec2f thrustVel = Vec2f(ship.rcs_force, 0);
				//thrustVel.RotateByDegrees(blobAngle);
				starboard += thrustVel;

				if (!facingLeft)
				{ ship.port_thrust = true; }
				else
				{ ship.starboard_thrust = true; }
			}
			else
			{
				if (!facingLeft)
				{ ship.port_thrust = false; }
				else
				{ ship.starboard_thrust = false; }
			}
		}
		else
		{
			ship.port_thrust = false;
			ship.starboard_thrust = false;

			if(left)
			{
				addedSpin -= ship.rcs_force;

				if (facingLeft)
				{
					ship.portBow_thrust = true;
					ship.starboardQuarter_thrust = true;
				}
				else
				{
					ship.portQuarter_thrust = true;
					ship.starboardBow_thrust = true;
				}
			}
			else
			{
				if (facingLeft)
				{
					ship.portBow_thrust = false;
					ship.starboardQuarter_thrust = false;
				}
				else
				{
					ship.portQuarter_thrust = false;
					ship.starboardBow_thrust = false;
				}
			}
			
			if(right)
			{
				addedSpin += ship.rcs_force;

				if (!facingLeft)
				{
					ship.portBow_thrust = true;
					ship.starboardQuarter_thrust = true;
				}
				else
				{
					ship.portQuarter_thrust = true;
					ship.starboardBow_thrust = true;
				}
			}
			else
			{
				if (!facingLeft)
				{
					ship.portBow_thrust = false;
					ship.starboardQuarter_thrust = false;
				}
				else
				{
					ship.portQuarter_thrust = false;
					ship.starboardBow_thrust = false;
				}
			}
		}

		Vec2f addedVel = Vec2f_zero;
		if (isShifting) //does not divide thrust if using rotational thrust
		{
			float thrustReduction = Maths::Min(1.0f / (float(keysPressedAmount) * 0.7f), 1.0f); //divide thrust between multiple sides
			forward *= thrustReduction;
			backward *= thrustReduction;
			port *= thrustReduction;
			starboard *= thrustReduction;

			addedVel += port;
			addedVel += starboard;
		}

		addedVel += forward; 
		addedVel += backward;
		
		addedVel.RotateByDegrees(blobAngle); //rotate thrust to match ship
		
		thisVel += addedVel * moveVars.engineFactor; //final speed modified by engine variable
		blobSpinVel += addedSpin * moveVars.engineFactor * moveVars.turnSpeedFactor; //spin velocity also affected by engine force
	}
	else
	{
		ship.forward_thrust = false;
		ship.backward_thrust = false;
		ship.port_thrust = false;
		ship.portBow_thrust = false;
		ship.portQuarter_thrust = false;
		ship.starboard_thrust = false;
		ship.starboardBow_thrust = false;
		ship.starboardQuarter_thrust = false;
	}

	const bool isWarp = thisBlob.get_bool(isWarpBoolString);
	f32 maxSpeed = ship.max_speed * moveVars.maxSpeedFactor;
	if (isWarp)
	{
		thisVel = Vec2f(maxSpeed, 0).RotateByDegrees(blobAngle-90);
	}
	else if ((maxSpeed != 0 && thisVel.getLength() > maxSpeed)) //max speed logic - 0 means no cap
	{
		thisVel.Normalize();
		thisVel *= maxSpeed;
	}


	//map wall collision
	float wallWidth = 30.0f;
	float bounceSpeed = 0.2f;
	if (thisPos.y >=  (map.tilemapheight*8) - wallWidth) //if too high or too low, bounce back
	{
		thisVel = Vec2f(thisVel.x,-bounceSpeed);
	}
	else if (thisPos.y <= wallWidth)
	{
		thisVel = Vec2f(thisVel.x,bounceSpeed);
	}
	else if (thisPos.x >=  (map.tilemapwidth*8) - wallWidth) //if too left or too right, bounce back
	{
		thisVel = Vec2f(-bounceSpeed,thisVel.y);
	}
	else if (thisPos.x <= wallWidth)
	{
		thisVel = Vec2f(bounceSpeed,thisVel.y);
	}

	// turn speed cap
	f32 maxTurnSpeed = ship.ship_turn_speed;
	if (blobSpinVel > maxTurnSpeed)
	{
		blobSpinVel = maxTurnSpeed;
	}
	else if (blobSpinVel < -maxTurnSpeed)
	{
		blobSpinVel = -maxTurnSpeed;
	}

	//applies speed and rotation changes
	if (oldVel != thisVel) //if thisVel changed, set new velocity
	{
		thisBlob.setVelocity(thisVel);
	}
	if (oldSpinVel != blobSpinVel) //if spin changed, set new spin
	{
		thisBlob.setAngularVelocity(blobSpinVel);
	}

	CleanUp(this, thisBlob, moveVars);
}

void checkWarp( CBlob@ thisBlob, bool isWheelButton, Vec2f thisPos, Vec2f thisVel, float blobAngle, MediumshipInfo@ ship, SpaceshipVars@ moveVars, bool is_client )
{
	const u8 activationCost = 50;
	const u8 upkeepCost = 10;
	const u32 warpLoadTime = 200;

	u32 m3Time = thisBlob.get_u32( "m3_heldTime" );
	u32 m3Cooldown = thisBlob.get_u32( "m3_cooldown" );

	bool onCooldown = m3Cooldown > 0;
	if (onCooldown) thisBlob.set_u32( "m3_cooldown", m3Cooldown-1 );

	if (!isWheelButton || thisBlob.get_s32(absoluteCharge_string) < upkeepCost)
	{
		if (thisBlob.get_bool(isWarpBoolString))
		{
			if (is_client) makeWarpShockwave( thisPos ); // CommonFX.as
			thisBlob.set_bool(isWarpBoolString, false);  // SpaceshipGlobal.as
		}

		if (m3Time > 0) // depower
		{
			thisBlob.set_u32( "m3_cooldown", 40 );
		}

		thisBlob.set_u32( "m3_heldTime", 0 );
		return;
	}

	if (onCooldown) return; // cannot charge warp drive if on cooldown

	u32 customTime = getGameTime() + thisBlob.getNetworkID();

	float engineStatus = 1.0f;
	float dragStatus = 1.0f;

	float warpLoadProgress = float(m3Time) / float(warpLoadTime);
	if (m3Time >= warpLoadTime)
	{
		engineStatus = 0.1f;
		dragStatus = 8.0f;
		if (thisBlob.get_s32(absoluteCharge_string) >= (activationCost+upkeepCost)) // minimum requirement
		{
			if (!thisBlob.get_bool(isWarpBoolString))
			{
				if (is_client) makeWarpShockwave( thisPos ); // CommonFX.as
				if (isServer()) removeCharge(thisBlob, activationCost, true);
				thisBlob.set_bool(isWarpBoolString, true); // SpaceshipGlobal.as
			}
		}
		if (thisBlob.get_bool(isWarpBoolString))
		{
			moveVars.turnSpeedFactor *= 7.0f; //boosts turn speed for warp
			moveVars.maxSpeedFactor *= 2.0f; // doubles max speed
		}
	}
	else
	{
		engineStatus = 0.5f * warpLoadProgress;
		dragStatus = 8.0f * warpLoadProgress;

		if (is_client)
		{
			float surgeBuildup = thisBlob.get_f32("surge_buildup");
			surgeBuildup += 1.0f + (25.0f * warpLoadProgress);
			if (surgeBuildup >= 100.0f)
			{
				makeWarpElectricSurge( thisPos, thisVel, blobAngle-90, 0.3f + warpLoadProgress); // CommonFX.as
				surgeBuildup = 0.0f;
			}
			thisBlob.set_f32("surge_buildup", surgeBuildup);
		}
	}

	// drain charge thrice a second while warping
	if (isServer() && customTime % 10 == 0)
	{
		removeCharge(thisBlob, thisBlob.get_bool(isWarpBoolString) ? upkeepCost : upkeepCost/2, true);
	}

	moveVars.engineFactor *= engineStatus; //cripples thruster efficacy
	moveVars.dragFactor *= dragStatus; // increases shipdrag
	
	if (m3Time < warpLoadTime) m3Time++; // caps at warpLoadTime ticks
	thisBlob.set_u32( "m3_heldTime", m3Time );
}