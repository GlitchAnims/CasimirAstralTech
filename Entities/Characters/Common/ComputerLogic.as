#include "SpaceshipGlobal.as"
#include "ChargeCommon.as"
#include "SmallshipCommon.as"
#include "MediumshipCommon.as"
#include "ComputerCommon.as"
#include "CommonFX.as"

#include "NavComp.as"
#include "BallisticsCalculator.as"

void onInit(CBlob@ this)
{
	//setup all calcs to false
	this.set_bool(hasNavCompString, false);
	this.set_bool(hasBallisticsString, false);
	this.set_bool(hasTargetingString, false);

	if (this.isMyPlayer())
	{

	}
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
	u16 thisNetID = this.getNetworkID();
	
	if ( (gameTime+thisNetID) % 30 == 0)
	{
		updateInventoryCPU( this );
	}

	if (this.get_s32(absoluteCharge_string) <= 0) //no charge? fucked.
	{ return; }

	const bool hasNavComp = this.get_bool(hasNavCompString);
	const bool hasBallistics = this.get_bool(hasBallisticsString);
	const bool hasTargeting = this.get_bool(hasTargetingString);

	if (!hasNavComp && !hasBallistics && !hasTargeting)
	{ return; }

	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	int teamNum = this.getTeamNum();
	f32 blobAngle = this.getAngleDegrees();
	blobAngle = Maths::Abs(blobAngle) % 360;

	ComputerBlobInfo ownerInfo;
	ownerInfo.current_pos = thisPos;
	ownerInfo.current_vel = thisVel;
	ownerInfo.team_num = teamNum;
	ownerInfo.blob_angle = blobAngle;

	if (hasNavComp)
	{
		runNavigation( this, gameTime, ticksASecond, thisNetID, ownerInfo );
	}
	if (hasBallistics)
	{
		runBallistics( this, gameTime, ticksASecond, thisNetID, ownerInfo );
	}
	if (hasTargeting)
	{
		//runTargeting( this, gameTime, ticksASecond, thisNetID, ownerInfo );
		//TODO
	}

	if (!this.isMyPlayer()) //if not my player, do not do the calcs - CUTOFF POINT
	{ return; }

	Vec2f aimVec = Vec2f(300.0f, 0);
	aimVec.RotateByDegrees(blobAngle); //aim vector
	drawParticleLine( thisPos, aimVec + thisPos, Vec2f_zero, greenConsoleColor, 0, 15.0f); //ship aim line

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

void runNavigation( CBlob@ ownerBlob, u32 gameTime, u32 ticksASecond, u16 thisNetID, ComputerBlobInfo@ ownerInfo )
{
	if (!ownerBlob.isMyPlayer()) //if not my player, do not do the calcs - CUTOFF POINT
	{ return; }

	const int teamNum = ownerInfo.team_num;

	CBlob@[] hulls;
	getBlobsByTag("hull", @hulls);
	for(uint i = 0; i < hulls.length(); i++)
	{
		CBlob@ b = hulls[i];
		if (b == null)
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
			smallshipNavigation( b, ticksASecond, b is ownerBlob, color );
		}
		else if (b.hasTag(mediumTag))
		{
			mediumshipNavigation( b, ticksASecond, b is ownerBlob, color );
		}
	}
}


void runBallistics( CBlob@ ownerBlob, u32 gameTime, u32 ticksASecond, u16 thisNetID, ComputerBlobInfo@ ownerInfo )
{
	if (isServer() && (gameTime+thisNetID) % 45 == 0) //remove charge one every 1.5 seconds
	{
		removeCharge(ownerBlob, 1, true);
	}

	if (!ownerBlob.isMyPlayer()) //if not my player, do not do the calcs - CUTOFF POINT
	{ return; }

	string ownerBlobName = ownerBlob.getName();
	switch (ownerBlobName.getHash())
	{
		case 0:
		break;
		case 1:
		break;
		case 2:
		break;

		default:
		{
			fighterBallistics( ownerBlob, ownerInfo, ticksASecond );
		}
	}
}


void runTargeting( CBlob@ ownerBlob, u32 gameTime, u32 ticksASecond, u16 thisNetID, ComputerBlobInfo@ ownerInfo )
{
	//TODO
}

void updateInventoryCPU( CBlob@ this )
{
	CInventory@ inv = this.getInventory();
	if (inv == null)
	{ return; }

	this.set_bool(hasNavCompString, inv.isInInventory("nav_comp", 1));
	this.set_bool(hasBallisticsString, inv.isInInventory("ballistics_calc", 1));
	this.set_bool(hasTargetingString, inv.isInInventory("targeting_unit", 1));
}