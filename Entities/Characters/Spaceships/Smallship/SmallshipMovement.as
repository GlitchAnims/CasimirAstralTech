// Fighter Movement

#include "SmallshipCommon.as"
#include "SpaceshipVars.as"
#include "MakeDustParticle.as";
#include "KnockedCommon.as";

void onInit(CMovement@ this)
{
	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null)
	{ return; }

	this.getCurrentScript().removeIfTag = "dead";

	thisBlob.set_u32("accelSoundDelay",0);
	thisBlob.set_s32("rightTap",0);
	thisBlob.set_s32("leftTap",0);
	thisBlob.set_s32("upTap",0);
	thisBlob.set_s32("downTap",0);

	if (isServer())
	{
		CAttachment@ attachments = thisBlob.getAttachments();
		if (attachments == null)
		{ return; }

		Vec2f ownerPos = thisBlob.getPosition();

		AttachmentPoint@ slot1 = attachments.getAttachmentPointByName("ENGINESLOT1");

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
					blob.set_u8("soundemit_num", 0);
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

	CMap@ map = getMap(); //standard map check
	if (map is null)
	{ return; }

	SpaceshipVars@ moveVars;
	if (!thisBlob.get("moveVars", @moveVars))
	{ return; }

	SmallshipInfo@ ship;
	if (!thisBlob.get( "shipInfo", @ship )) 
	{ return; }
	
	const bool left		= thisBlob.isKeyPressed(key_left);
	const bool right	= thisBlob.isKeyPressed(key_right);
	const bool up		= thisBlob.isKeyPressed(key_up);
	const bool down		= thisBlob.isKeyPressed(key_down);

	const bool isDocked = thisBlob.isAttached();
	
	bool[] allKeys =
	{
		up,
		down,
		left,
		right
	};

	u8 keysPressedAmount = 0;
	if (!isDocked)
	{
		for (uint i = 0; i < allKeys.length; i ++)
		{
			bool currentKey = allKeys[i];
			if (currentKey)
			{ keysPressedAmount++; }
		}
	}
	
	const bool isknocked = isKnocked(thisBlob) || (thisBlob.get_bool("frozen") == true);
	const bool is_client = isClient();

	Vec2f thisVel = thisBlob.getVelocity();
	Vec2f oldVel = thisVel;
	Vec2f thisPos = thisBlob.getPosition();
	f32 blobAngle = thisBlob.getAngleDegrees();
	blobAngle = (blobAngle+360.0f) % 360;

	Vec2f aimPos = thisBlob.getAimPos();
	Vec2f aimVec = aimPos - thisPos;
	f32 aimAngle = -aimVec.getAngleDegrees();

	if (blobAngle != aimAngle && !isDocked) //aiming logic
	{
		f32 turnSpeed = ship.ship_turn_speed * moveVars.turnSpeedFactor; //multiplier for turn speed

		f32 angleDiff = Maths::Abs(blobAngle - aimAngle);
		angleDiff = (angleDiff + 180) % 360 - 180;

		if (turnSpeed <= 0 || (angleDiff < turnSpeed && angleDiff > -turnSpeed)) //if turn difference is smaller than turn speed, snap to it
		{
			thisBlob.setAngleDegrees(aimAngle);
		}
		else
		{
			f32 turnAngle = angleDiff > 0 ? -turnSpeed : turnSpeed; //either left or right turn
			thisBlob.setAngleDegrees(blobAngle + turnAngle);
		}
		blobAngle = thisBlob.getAngleDegrees();
	}
	
	
	CShape@ shape = thisBlob.getShape();
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

	if (keysPressedAmount != 0 && !isDocked)
	{
		Vec2f forward		= Vec2f_zero;
		Vec2f backward		= Vec2f_zero;
		Vec2f port			= Vec2f_zero;
		Vec2f starboard		= Vec2f_zero;

		if(up)
		{
			Vec2f thrustVel = Vec2f(ship.main_engine_force, 0);
			thrustVel.RotateByDegrees(blobAngle);
			forward += thrustVel;
			ship.forward_thrust = true;
		}
		else
		{ ship.forward_thrust = false; }

		if(down)
		{
			Vec2f thrustVel = Vec2f(ship.secondary_engine_force, 0);
			thrustVel.RotateByDegrees(blobAngle + 180.0f);
			backward += thrustVel;
			ship.backward_thrust = true;
		}
		else
		{ ship.backward_thrust = false; }

		if(left)
		{
			Vec2f thrustVel = Vec2f(ship.rcs_force, 0);
			thrustVel.RotateByDegrees(blobAngle + 270.0f);
			port += thrustVel;
			ship.port_thrust = true;
		}
		else
		{ ship.port_thrust = false; }
		
		if(right)
		{
			Vec2f thrustVel = Vec2f(ship.rcs_force, 0);
			thrustVel.RotateByDegrees(blobAngle + 90.0f);
			starboard += thrustVel;
			ship.starboard_thrust = true;
		}
		else
		{ ship.starboard_thrust = false; }

		Vec2f addedVel = Vec2f_zero;
		float thrustReduction = Maths::Min(1.0f / (float(keysPressedAmount) * 0.8f), 1.0f); //divide thrust between multiple sides
		addedVel += forward * thrustReduction;
		addedVel += backward * thrustReduction;
		addedVel += port * thrustReduction;
		addedVel += starboard * thrustReduction;
		
		thisVel += addedVel * moveVars.engineFactor; //final speed modified by engine variable
	}
	else
	{
		ship.forward_thrust = false;
		ship.backward_thrust = false;
		ship.port_thrust = false;
		ship.starboard_thrust = false;
	}

	float wallWidth = 8.0f;
	float bounceSpeed = 0.2f;
	if (thisPos.y > (map.tilemapheight*8) - wallWidth) //if too high or too low, bounce back
	{
		thisVel = Vec2f(thisVel.x,-bounceSpeed);
		thisBlob.setPosition(Vec2f(thisPos.x,(map.tilemapheight*8) - wallWidth));
	}
	else if (thisPos.y < wallWidth)
	{
		thisVel = Vec2f(thisVel.x,bounceSpeed);
		thisBlob.setPosition(Vec2f(thisPos.x,wallWidth));
	}
	else if (thisPos.x > (map.tilemapwidth*8) - wallWidth) //if too left or too right, bounce back
	{
		thisVel = Vec2f(-bounceSpeed,thisVel.y);
		thisBlob.setPosition(Vec2f((map.tilemapwidth*8) - wallWidth,thisPos.y));
	}
	else if (thisPos.x < wallWidth)
	{
		thisVel = Vec2f(bounceSpeed,thisVel.y);
		thisBlob.setPosition(Vec2f(wallWidth,thisPos.y));
	}

	f32 maxSpeed = ship.max_speed * moveVars.maxSpeedFactor;
	if (maxSpeed != 0 && thisVel.getLength() > maxSpeed) //max speed logic - 0 means no cap
	{
		thisVel.Normalize();
		thisVel *= maxSpeed;
	}

	if (oldVel != thisVel) //if thisVel changed, set new velocity
	{
		thisBlob.setVelocity(thisVel);
	}
	
	CleanUp(this, thisBlob, moveVars);
}