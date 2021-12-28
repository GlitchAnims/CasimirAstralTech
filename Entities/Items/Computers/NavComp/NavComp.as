#include "SpaceshipGlobal.as"
#include "SmallshipCommon.as"
#include "MediumshipCommon.as"
#include "ComputerCommon.as"
#include "CommonFX.as"

const f32 rotationRingRadius = 40.0f;

void smallshipNavigation( CBlob@ hullBlob, u32 ticksASecond = 30, bool isTrueOwner = false, SColor color = greenConsoleColor )
{
	SmallshipInfo@ ship;
	if (!hullBlob.get( "shipInfo", @ship )) 
	{ return; }

	Vec2f hullPos = hullBlob.getPosition();
	Vec2f hullVel = hullBlob.getVelocity();
	f32 hullAngle = hullBlob.getAngleDegrees();
	hullAngle = Maths::Abs(hullAngle) % 360;

	if (!isTrueOwner) //only draw aim line for ships that are not the owner of the CPU
	{
		drawSmallAimLine( hullPos, hullAngle, color );
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

void mediumshipNavigation( CBlob@ hullBlob, u32 ticksASecond = 30, bool isTrueOwner = false, SColor color = greenConsoleColor )
{
	MediumshipInfo@ ship;
	if (!hullBlob.get( "shipInfo", @ship )) 
	{ return; }

	Vec2f hullPos = hullBlob.getPosition();
	Vec2f hullVel = hullBlob.getVelocity();
	f32 hullAngle = hullBlob.getAngleDegrees() + 270.0f;
	hullAngle = Maths::Abs(hullAngle) % 360;

	if (!isTrueOwner) //only draw aim line for ships that are not the owner of the CPU
	{
		drawSmallAimLine( hullPos, hullAngle, color );
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

void drawSmallAimLine( Vec2f hullPos = Vec2f_zero, f32 hullAngle = 0, SColor color = greenConsoleColor )
{
	Vec2f aimVec = Vec2f(60.0f, 0);
	aimVec.RotateByDegrees(hullAngle); //aim vector
	drawParticleLine( hullPos, aimVec + hullPos, Vec2f_zero, color, 0, 3.0f); //others aim line
}