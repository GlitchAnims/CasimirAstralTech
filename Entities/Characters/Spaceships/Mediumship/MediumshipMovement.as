// Fighter Movement

#include "MediumshipCommon.as"
#include "SpaceshipVars.as"
#include "MakeDustParticle.as";
#include "KnockedCommon.as";

void onInit(CMovement@ this)
{
	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null)
	{ return; }

	thisBlob.set_u32("accelSoundDelay",0);

	this.getCurrentScript().removeIfTag = "dead";

	thisBlob.set_s32("rightTap",0);
	thisBlob.set_s32("leftTap",0);
	thisBlob.set_s32("upTap",0);
	thisBlob.set_s32("downTap",0);

	thisBlob.set_bool("movementFirstTick", true);
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

	Vec2f pos = thisBlob.getPosition();
	Vec2f vel = thisBlob.getVelocity();
	Vec2f oldVel = vel;
	
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
	const bool isShifting = thisBlob.get_bool("shifting");
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
		
		vel += addedVel * moveVars.engineFactor; //final speed modified by engine variable
		blobSpinVel += addedSpin * moveVars.engineFactor; //spin velocity also affected by engine force
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

	f32 maxTurnSpeed = ship.ship_turn_speed;
	if (blobSpinVel > maxTurnSpeed)
	{
		blobSpinVel = maxTurnSpeed;
	}
	else if (blobSpinVel < -maxTurnSpeed)
	{
		blobSpinVel = -maxTurnSpeed;
	}

	if (oldVel != vel) //if vel changed, set new velocity
	{
		thisBlob.setVelocity(vel);
	}
	if (oldSpinVel != blobSpinVel) //if spin changed, set new spin
	{
		thisBlob.setAngularVelocity(blobSpinVel);
	}
	
	CleanUp(this, thisBlob, moveVars);
}