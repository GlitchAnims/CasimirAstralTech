// Fighter Movement

#include "MediumshipCommon.as"
#include "ChargeCommon.as"
#include "SpaceshipVars.as"
#include "MakeDustParticle.as";
#include "KnockedCommon.as";
#include "HoverMessage.as"
#include "CommonFX.as"
#include "FaradayCommon.as"

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
					blob.set_u16("ownerBlobID", thisBlob.getNetworkID());
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
					blob.set_u16("ownerBlobID", thisBlob.getNetworkID());
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

	u8 faradayTime = thisBlob.get_u8(faradayTimeString);
	u8 faradayPhase = thisBlob.get_u8(faradayPhaseString);
	if (isWheelButton && faradayTime == 0)
	{
		thisBlob.set_u8(faradayNextString, faradayPhase == 3 ? 0 : faradayPhase+1);

		faradayTime = 45;
		thisBlob.set_u8(faradayTimeString, faradayTime);
	}

	if (faradayTime == 0)
	{
		u8 faradayNext = thisBlob.get_u8(faradayNextString);
		if (faradayPhase != faradayNext)
		{
			thisBlob.set_u8(faradayPhaseString, faradayNext);
			moveVars.is_warp = faradayNext == 1 || faradayNext == 2;
			thisBlob.set_bool(faradayIsAssaultBoolString, faradayNext == 2 || faradayNext == 3);
		}
	}
	else
	{
		if (faradayTime > 0) thisBlob.set_u8(faradayTimeString, faradayTime-1);
	}

	if (moveVars.is_warp)
	{
		moveVars.engineFactor *= 2.5f;
	}
	
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

	keysPressedAmount = faradayTime > 0 ? 0 : keysPressedAmount == 0 ? 1 : keysPressedAmount;
	
	const bool isknocked = isKnocked(thisBlob) || (thisBlob.get_bool("frozen") == true);
	const bool is_client = isClient();

	Vec2f thisPos = thisBlob.getPosition();
	Vec2f thisVel = thisBlob.getVelocity();
	Vec2f oldVel = thisVel;
	
	f32 blobAngle = thisBlob.getAngleDegrees();
	blobAngle = Maths::Abs(blobAngle) % 360;

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
			Vec2f thrustVel = Vec2f(ship.main_engine_force, 0);
			//thrustVel.RotateByDegrees(blobAngle);
			forward += thrustVel;
			moveVars.forward_thrust = true;
		}
		else
		{ moveVars.forward_thrust = false; }

		if(down)
		{
			Vec2f thrustVel = Vec2f(-ship.secondary_engine_force, 0);
			//thrustVel.RotateByDegrees(blobAngle);
			backward += thrustVel;
			moveVars.backward_thrust = true;
		}
		else
		{ moveVars.backward_thrust = false; }

		if (!isShifting)
		{
			moveVars.portBow_thrust = false;
			moveVars.portQuarter_thrust = false;
			moveVars.starboardBow_thrust = false;
			moveVars.starboardQuarter_thrust = false;

			if(left)
			{
				Vec2f thrustVel = Vec2f(0, -ship.secondary_engine_force);
				port += thrustVel;

				moveVars.starboard_thrust = true;
			}
			else
			{
				moveVars.starboard_thrust = false;
			}
			
			if(right)
			{
				Vec2f thrustVel = Vec2f(0, ship.secondary_engine_force);
				starboard += thrustVel;

				moveVars.port_thrust = true;
			}
			else
			{
				moveVars.port_thrust = false;
			}

			Vec2f thisAimPos = thisBlob.getAimPos();
			Vec2f thisAimVec = thisAimPos - thisPos;
			float thisAimAngle = thisAimVec.getAngleDegrees();

			float angleDiff = (-thisAimAngle+360.0f) - blobAngle;
			angleDiff += angleDiff > 180 ? -360 : angleDiff < -180 ? 360 : 0;
			
			angleDiff /= 180.0f; // sets it from 0 to 1

			addedSpin = ship.rcs_force * angleDiff;

			if ((addedSpin > 0 && blobSpinVel < 0) || (addedSpin < 0 && blobSpinVel > 0))
			{
				addedSpin *= 3.0f;
			}
		}
		else
		{
			moveVars.port_thrust = false;
			moveVars.starboard_thrust = false;

			if(left) addedSpin -= ship.rcs_force;
				
			moveVars.portQuarter_thrust = left;
			moveVars.starboardBow_thrust = left;
			
			if(right) addedSpin += ship.rcs_force;
			moveVars.portBow_thrust = right;
			moveVars.starboardQuarter_thrust = right;

		}

		Vec2f addedVel = Vec2f_zero;
		if (!isShifting) //does not divide thrust if using rotational thrust
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
		moveVars.forward_thrust = false;
		moveVars.backward_thrust = false;
		moveVars.port_thrust = false;
		moveVars.portBow_thrust = false;
		moveVars.portQuarter_thrust = false;
		moveVars.starboard_thrust = false;
		moveVars.starboardBow_thrust = false;
		moveVars.starboardQuarter_thrust = false;
	}

	f32 maxSpeed = ship.max_speed * moveVars.maxSpeedFactor;
	if ((maxSpeed != 0 && thisVel.getLength() > maxSpeed)) //max speed logic - 0 means no cap
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

void showMessage( CBlob@ blob, string msg )
{
	if (!blob.isMyPlayer())
	{ return; }

	if (msg.length() <= 0)
	{ return; }

	ShipWarningMessage@ message = cast<ShipWarningMessage>(add_message(
				ShipWarningMessage(msg),
				true
			));
}