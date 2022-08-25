// Fighter Movement

#include "SmallshipCommon.as"
#include "SpaceshipVars.as"
#include "MakeDustParticle.as";
#include "KnockedCommon.as";

void onInit(CMovement@ this)
{
	this.getBlob().set_u32("accelSoundDelay",0);

	this.getCurrentScript().removeIfTag = "dead";

	this.getBlob().set_s32("rightTap",0);
	this.getBlob().set_s32("leftTap",0);
	this.getBlob().set_s32("upTap",0);
	this.getBlob().set_s32("downTap",0);
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

	Vec2f vel = thisBlob.getVelocity();
	Vec2f oldVel = vel;
	Vec2f pos = thisBlob.getPosition();
	f32 blobAngle = thisBlob.getAngleDegrees();
	blobAngle = (blobAngle+360.0f) % 360;

	Vec2f aimPos = thisBlob.getAimPos();
	Vec2f aimVec = aimPos - pos;
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
		addedVel += forward / float(keysPressedAmount); //divide thrust between multiple sides
		addedVel += backward / float(keysPressedAmount);
		addedVel += port / float(keysPressedAmount);
		addedVel += starboard / float(keysPressedAmount);
		
		vel += addedVel * moveVars.engineFactor; //final speed modified by engine variable
	}
	else
	{
		ship.forward_thrust = false;
		ship.backward_thrust = false;
		ship.port_thrust = false;
		ship.starboard_thrust = false;
	}

	if (thisBlob.getPosition().y >=  (map.tilemapheight*8) - 8) //if too high or too low, bounce back
	{
		vel = Vec2f(vel.x,-1);
	}
	else if (thisBlob.getPosition().y <= 2)
	{
		vel = Vec2f(vel.x,1);
	}
	else if (thisBlob.getPosition().x >=  (map.tilemapwidth*8) - 8) //if too left or too right, bounce back
	{
		vel = Vec2f(-1,vel.y);
	}
	else if (thisBlob.getPosition().x <= 8)
	{
		vel = Vec2f(1,vel.y);
	}

	f32 maxSpeed = ship.max_speed * moveVars.maxSpeedFactor;
	if (maxSpeed != 0 && vel.getLength() > maxSpeed) //max speed logic - 0 means no cap
	{
		vel.Normalize();
		vel *= maxSpeed;
	}

	if (oldVel != vel) //if vel changed, set new velocity
	{
		thisBlob.setVelocity(vel);
	}
	
	CleanUp(this, thisBlob, moveVars);
}