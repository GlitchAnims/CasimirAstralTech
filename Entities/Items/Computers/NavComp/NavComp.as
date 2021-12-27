#include "SpaceshipGlobal.as"
#include "ChargeCommon.as"
#include "SmallshipCommon.as"
#include "MediumshipCommon.as"
#include "ComputerCommon.as"
#include "CommonFX.as"

const f32 secondsBeforeDeath = 5.0f;
const f32 rotationRingRadius = 40.0f;

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	if (shape != null)
	{
		shape.getConsts().mapCollisions = true;
		shape.SetGravityScale(0.0f);
	}

	this.set_bool(firstTickString, true); //SpaceshipGlobal.as
	this.set_u32("time_of_death", getGameTime() + (secondsBeforeDeath * getTicksASecond()));

	this.SetMapEdgeFlags(CBlob::map_collide_up | CBlob::map_collide_down | CBlob::map_collide_sides);
	/*
	ComputerTargetInfo compInfo;
	compInfo.current_pos = Vec2f_zero; //this tick position
	compInfo.last_pos = Vec2f_zero; //last tick position
	compInfo.current_vel = Vec2f_zero; //this tick velocity
	compInfo.last_vel = Vec2f_zero; //last tick velocity

	BallisticsOwnerInfo ownerInfo;
	ownerInfo.tickInfo.resize(999999);
	ownerInfo.tickInfo.insertAt(10, compInfo);
	this.set("ownerInfo", ownerInfo);
	*/

}

void onTick(CBlob@ this)
{
	u32 gameTime = getGameTime();
	u32 ticksASecond = getTicksASecond();

	if (isServer())
	{
		if (!this.isInInventory() && !this.isAttached())
		{
			if (gameTime >= this.get_u32("time_of_death"))
			{
				this.server_Die();
			}
			return;
		}
		else
		{
			this.set_u32("time_of_death", getGameTime() + (secondsBeforeDeath * getTicksASecond()));
		}
	}

	
	CBlob@ ownerBlob = this.getInventoryBlob();
	if (ownerBlob == null)
	{ return; }

	if (!ownerBlob.isMyPlayer()) //if not my player, do not do the calcs - CUTOFF POINT
	{ return; }

	if (ownerBlob.get_s32(absoluteCharge_string) <= 0) //no charge? fucked.
	{ return; }

	CPlayer@ ownerPlayer = ownerBlob.getPlayer();
	if (ownerPlayer == null)
	{ return; }
	int playerPing = ownerPlayer.getPing();
	u32 pingTicks = (float(playerPing) / 1000.0f) * ticksASecond;

	int teamNum = ownerBlob.getTeamNum();
	
	if (ownerBlob.hasTag(smallTag)) 
	{ 
		smallshipNavigation( this, ownerBlob, ticksASecond, true );
	}
	else if (ownerBlob.hasTag(mediumTag))
	{
		mediumshipNavigation( this, ownerBlob, ticksASecond, true );
	}

	CBlob@[] hulls;
	getBlobsByTag("hull", @hulls);
	for(uint i = 0; i < hulls.length(); i++)
	{
		CBlob@ b = hulls[i];
		if (b == null || b is ownerBlob)
		{ continue; }

		f32 targetDist = b.getDistanceTo(ownerBlob);
		if (targetDist > 512) //too far away, don't continue rendering
		{ continue; }

		SColor color = greenConsoleColor;
		if (b.getTeamNum() != teamNum)
		{ 
			color = yellowConsoleColor; //yellow for enemies
		}

		if (b.hasTag(smallTag))
		{
			smallshipNavigation( this, b, ticksASecond, false, color );
		}
		else if (b.hasTag(mediumTag))
		{
			mediumshipNavigation( this, b, ticksASecond, false, color );
		}
	}

	/*ComputerTargetInfo compInfo;
	compInfo.current_pos = ownerBlob.getPosition(); //this tick position
	compInfo.last_pos = ownerBlob.getOldPosition(); //last tick position
	compInfo.current_vel = ownerBlob.getVelocity(); //this tick velocity
	compInfo.last_vel = ownerBlob.getOldVelocity(); //last tick velocity

	
	u8 gameTimeCast = gameTime;
	u8 varID = gameTimeCast + pingTicks;
	string varName = "ownerInfo" + varID;
	this.set(varName, compInfo);

	if (!this.get( "ownerInfo"+gameTimeCast, @compInfo )) 
	{ return; }*/
	
	/*
	BallisticsOwnerInfo@ ownerInfo;
	if (!this.get( "ownerInfo", @ownerInfo )) 
	{ return; }
	ComputerTargetInfo compInfo; //gets info for this tick
	//compInfo = ownerInfo.tickInfo[gameTime];
	compInfo = ownerInfo.tickInfo.opIndex(gameTime);
	if (compInfo == null)
	{ return; }
	Vec2f ownerPos = compInfo.current_pos;
	Vec2f ownerVel = compInfo.current_vel;

	compInfo.current_pos = ownerBlob.getPosition(); //this tick position
	compInfo.last_pos = ownerBlob.getOldPosition(); //last tick position
	compInfo.current_vel = ownerBlob.getVelocity(); //this tick velocity
	compInfo.last_vel = ownerBlob.getOldVelocity(); //last tick velocity
	
	ownerInfo.tickInfo.insertAt(gameTime + playerPing, compInfo);
	this.set("ownerInfo", ownerInfo);*/
	
}

void smallshipNavigation( CBlob@ navComp, CBlob@ hullBlob, u32 ticksASecond = 30, bool isTrueOwner = false, SColor color = greenConsoleColor )
{
	SmallshipInfo@ ship;
	if (!hullBlob.get( "shipInfo", @ship )) 
	{ return; }

	Vec2f hullPos = hullBlob.getPosition();
	Vec2f hullVel = hullBlob.getVelocity();
	f32 hullAngle = hullBlob.getAngleDegrees();
	hullAngle = Maths::Abs(hullAngle) % 360;

	if (isTrueOwner) //laser sight for owner, small indicator line for everyone else
	{
		Vec2f aimVec = Vec2f(300.0f, 0);
		aimVec.RotateByDegrees(hullAngle); //aim vector
		f32 shotSpeed = ship.shot_speed;
		drawParticleLine( hullPos, aimVec + hullPos, Vec2f_zero, greenConsoleColor, 0, shotSpeed/2); //owner aim line
	}
	else
	{
		Vec2f aimVec = Vec2f(60.0f, 0);
		aimVec.RotateByDegrees(hullAngle); //aim vector
		drawParticleLine( hullPos, aimVec + hullPos, Vec2f_zero, color, 0, 3.0f); //others aim line
	}
	

	Vec2f travelVec = hullVel * getTicksASecond(); //gets a full second of travel
	f32 shipSpeed = hullVel.getLength();
	Vec2f navPIP = travelVec + hullPos;
	Vec2f navPIP2 = (travelVec/2) + hullPos;

	drawParticleCircle(navPIP, 5.0f, Vec2f_zero, color, 0, 2.0f); //navigation pip
	drawParticleLine(hullPos, navPIP, Vec2f_zero, color, 0, shipSpeed); //navigation line

	//impulse calculation
	Vec2f thrustVec = Vec2f_zero; 
	u8 thrusterAmount = 0;

	if (ship.forward_thrust)
	{
		Vec2f forwardAccel = Vec2f(ship.main_engine_force, 0);
		thrustVec += forwardAccel;
		thrusterAmount++;
	}
	if (ship.backward_thrust)
	{
		Vec2f backwardAccel = Vec2f(-ship.secondary_engine_force, 0);
		thrustVec += backwardAccel;
		thrusterAmount++;
	}
	if (ship.port_thrust)
	{
		Vec2f portAccel = Vec2f(0, -ship.rcs_force);
		thrustVec += portAccel;
		thrusterAmount++;
	}
	if (ship.starboard_thrust)
	{
		Vec2f starboardAccel = Vec2f(0, ship.rcs_force);
		thrustVec += starboardAccel;
		thrusterAmount++;
	}

	if (thrusterAmount == 0) //no keys pressed, no calcs
	{ return; }

	thrustVec /= thrusterAmount; //divide by thrusters active
	thrustVec.RotateByDegrees(hullAngle); //rotate to match ship rotation
	thrustVec *= ticksASecond * 5; //gets a full second of thrust

	Vec2f thrustPIP = thrustVec + hullPos;

	makeBlobTriangle(thrustPIP, -thrustVec.getAngleDegrees(), Vec2f(4.0f, 3.0f), 1.0f, color); //thrust triangle
	//drawParticleLine(hullPos, thrustPIP, Vec2f_zero, color, 0, 3.0f); //thrust line
}

void mediumshipNavigation( CBlob@ navComp, CBlob@ hullBlob, u32 ticksASecond = 30, bool isTrueOwner = false, SColor color = greenConsoleColor )
{
	MediumshipInfo@ ship;
	if (!hullBlob.get( "shipInfo", @ship )) 
	{ return; }

	Vec2f hullPos = hullBlob.getPosition();
	Vec2f hullVel = hullBlob.getVelocity();
	f32 hullAngle = hullBlob.getAngleDegrees() + 270.0f;
	hullAngle = Maths::Abs(hullAngle) % 360;

	if (isTrueOwner) //laser sight for owner, small indicator line for everyone else
	{
		Vec2f aimVec = Vec2f(300.0f, 0);
		aimVec.RotateByDegrees(hullAngle); //aim vector
		f32 shotSpeed = ship.shot_speed;
		drawParticleLine( hullPos, aimVec + hullPos, Vec2f_zero, greenConsoleColor, 0, shotSpeed/2); //owner aim line
	}
	else
	{
		Vec2f aimVec = Vec2f(60.0f, 0);
		aimVec.RotateByDegrees(hullAngle); //aim vector
		drawParticleLine( hullPos, aimVec + hullPos, Vec2f_zero, color, 0, 3.0f); //others aim line
	}
	

	Vec2f travelVec = hullVel * getTicksASecond(); //gets a full second of travel
	f32 shipSpeed = hullVel.getLength();
	Vec2f navPIP = travelVec + hullPos;
	Vec2f navPIP2 = (travelVec/2) + hullPos;

	drawParticleCircle(navPIP, 5.0f, Vec2f_zero, color, 0, 2.0f); //navigation pip
	drawParticleLine(hullPos, navPIP, Vec2f_zero, color, 0, shipSpeed); //navigation line

	//impulse calculation
	const bool isShifting = hullBlob.get_bool("shifting");
	Vec2f thrustVec = Vec2f_zero; 
	u8 thrusterAmount = 0;

	if (ship.forward_thrust)
	{
		Vec2f forwardAccel = Vec2f(ship.main_engine_force, 0);
		thrustVec += forwardAccel;
		thrusterAmount++;
	}
	if (ship.backward_thrust)
	{
		Vec2f backwardAccel = Vec2f(-ship.secondary_engine_force, 0);
		thrustVec += backwardAccel;
		thrusterAmount++;
	}
	if (isShifting)
	{
		if (hullBlob.isFacingLeft())
		{
			if (ship.port_thrust)
			{
				Vec2f portAccel = Vec2f(0, -ship.rcs_force);
				thrustVec += portAccel;
				thrusterAmount++;
			}
			if (ship.starboard_thrust)
			{
				Vec2f starboardAccel = Vec2f(0, ship.rcs_force);
				thrustVec += starboardAccel;
				thrusterAmount++;
			}
		}
		else
		{
			if (ship.port_thrust)
			{
				Vec2f portAccel = Vec2f(0, ship.rcs_force);
				thrustVec += portAccel;
				thrusterAmount++;
			}
			if (ship.starboard_thrust)
			{
				Vec2f starboardAccel = Vec2f(0, -ship.rcs_force);
				thrustVec += starboardAccel;
				thrusterAmount++;
			}
		}
		
	}
	else
	{
		const bool portBow 			= ship.portBow_thrust;
		const bool portQuarter 		= ship.portQuarter_thrust;
		const bool starboardBow 	= ship.starboardBow_thrust;
		const bool starboardQuarter = ship.starboardQuarter_thrust;

		f32 leftArrowAngle = 180;
		f32 rightArrowAngle = 0;
		if (hullBlob.isFacingLeft())
		{
			leftArrowAngle = 0;
			rightArrowAngle = 180;
		}

		if (portBow && starboardQuarter && !portQuarter && !starboardBow)
		{
			makeBlobTriangle(hullPos + Vec2f(0, -rotationRingRadius*0.8f), rightArrowAngle, Vec2f(4.0f, 3.0f), 1.0f, color);
			makeBlobTriangle(hullPos + Vec2f(0, rotationRingRadius*0.8f), leftArrowAngle, Vec2f(4.0f, 3.0f), 1.0f, color);
		}
		else if (!portBow && !starboardQuarter && portQuarter && starboardBow)
		{
			makeBlobTriangle(hullPos + Vec2f(0, -rotationRingRadius*0.8f), leftArrowAngle, Vec2f(4.0f, 3.0f), 1.0f, color);
			makeBlobTriangle(hullPos + Vec2f(0, rotationRingRadius*0.8f), rightArrowAngle, Vec2f(4.0f, 3.0f), 1.0f, color);
		}
	}

	f32 hullSpinVel = hullBlob.getAngularVelocity(); //rotation speed
	f32 maxSpinVel = ship.ship_turn_speed; //max rotation speed
	if (hullSpinVel != 0)
	{
		f32 spinVelPercentage = Maths::Clamp(hullSpinVel / maxSpinVel, -1.0f, 1.0f);
		drawParticlePartialCircle(hullPos, rotationRingRadius, spinVelPercentage, 270.0f, color, 0, 2.0f);
	}

	if (thrusterAmount == 0) //no keys pressed, no calcs
	{ return; }

	if (isShifting)
	{
		thrustVec /= thrusterAmount; //divide by thrusters active
	}
	thrustVec.RotateByDegrees(hullAngle); //rotate to match ship rotation
	thrustVec *= ticksASecond * 100; //gets a full second of thrust

	Vec2f thrustPIP = thrustVec + hullPos;

	makeBlobTriangle(thrustPIP, -thrustVec.getAngleDegrees(), Vec2f(5.0f, 4.0f), 1.0f, color); //thrust triangle
	//drawParticleLine(hullPos, thrustPIP, Vec2f_zero, color, 0, 3.0f); //thrust line
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{

}

void onDie(CBlob@ this)
{
	
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return byBlob.hasTag("player");
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.doTickScripts = true;
	
	CBlob@ ownerBlob = this.getInventoryBlob();
	if (ownerBlob == null || ownerBlob.hasTag("dead"))
	{ return; }
	if (!ownerBlob.isMyPlayer())
	{ return; }

	ComputerTargetInfo compInfo;
	compInfo.current_pos = Vec2f_zero; //this tick position
	compInfo.last_pos = Vec2f_zero; //last tick position
	compInfo.current_vel = Vec2f_zero; //this tick velocity
	compInfo.last_vel = Vec2f_zero; //last tick velocity

	for(int i = 0; i < 256; i++)
	{
		string varName = "ownerInfo" + i;
		this.set(varName, compInfo);
	}
}