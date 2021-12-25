#include "SpaceshipGlobal.as"
#include "ChargeCommon.as"
#include "SmallshipCommon.as"
#include "ComputerCommon.as"
#include "CommonFX.as"

const f32 secondsBeforeDeath = 5.0f;

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
	if (ownerBlob == null || ownerBlob.hasTag("dead"))
	{ return; }

	if (isServer() && gameTime % 15 == 0)
	{
		removeCharge(ownerBlob, 1, true);
	}

	if (!ownerBlob.isMyPlayer()) //if not my player, do not do the calcs - CUTOFF POINT
	{ return; }

	if (ownerBlob.get_s32(absoluteCharge_string) <= 0) //no charge? fucked.
	{ return; }

	SmallshipInfo@ ship;
	if (!ownerBlob.get( "shipInfo", @ship )) 
	{ return; }

	CPlayer@ ownerPlayer = ownerBlob.getPlayer();
	if (ownerPlayer == null)
	{ return; }
	int playerPing = ownerPlayer.getPing();

	ComputerTargetInfo compInfo;
	compInfo.current_pos = ownerBlob.getPosition(); //this tick position
	compInfo.last_pos = ownerBlob.getOldPosition(); //last tick position
	compInfo.current_vel = ownerBlob.getVelocity(); //this tick velocity
	compInfo.last_vel = ownerBlob.getOldVelocity(); //last tick velocity

	u32 pingTicks = (float(playerPing) / 1000.0f) * getTicksASecond();
	u8 gameTimeCast = gameTime;
	u8 varID = gameTimeCast + pingTicks;
	string varName = "ownerInfo" + varID;
	this.set(varName, compInfo);

	if (!this.get( "ownerInfo"+gameTimeCast, @compInfo )) 
	{ return; }

	Vec2f ownerPos = compInfo.current_pos;
	Vec2f ownerVel = compInfo.current_vel;
	f32 shotSpeed = ship.shot_speed;
	f32 ownerAngle = ownerBlob.getAngleDegrees();
	ownerAngle = Maths::Abs(ownerAngle) % 360;
	int teamNum = ownerBlob.getTeamNum();
	
	Vec2f aimVec = Vec2f(256.0f, 0);
	aimVec.RotateByDegrees(ownerAngle); //owner aim vector
	makeBlobTriangle(ownerPos, ownerAngle, Vec2f(8.0f, 6.0f)); //owner triangle
	drawParticleLine( ownerPos, aimVec + ownerPos, Vec2f_zero, greenConsoleColor, 0, shotSpeed); //owner aim line

	CBlob@[] smallships;
	getBlobsByTag(smallTag, @smallships);
	for(uint i = 0; i < smallships.length(); i++)
	{
		CBlob@ b = smallships[i];
		if (b == null)
		{ continue; }

		if (b.getTeamNum() == teamNum)
		{ continue; }

		Vec2f bPos = b.getPosition();
		Vec2f bVel = b.getVelocity() - ownerVel;
		bPos += bVel * playerPing;
		f32 bAngle = b.getAngleDegrees();
		//f32 bSpeed = bVel.getLength();

		Vec2f targetVec = bPos - ownerPos;
		f32 targetDist = targetVec.getLength();
		if (targetDist > 512) //too far away, don't continue rendering
		{ continue; }
		f32 travelTicks = targetDist / shotSpeed;

		Vec2f futureTargetPos = bPos + (bVel*travelTicks);
		targetVec = futureTargetPos - ownerPos;
		f32 leadPipAngle = -targetVec.getAngleDegrees();

		f32 angleDiff = Maths::Abs(leadPipAngle - ownerAngle);
		angleDiff = (angleDiff + 180) % 360 - 180;
		SColor color = greenConsoleColor;
		if (angleDiff < 1.5f && angleDiff > -1.5f)
		{
			color = SColor(255, 255, 50, 50);
		}
		makeBlobTriangle(bPos, bAngle, Vec2f(8.0f, 6.0f)); //enemy triangle
		drawParticleLine( bPos, futureTargetPos, Vec2f_zero, color, 0, 3.0f);
		drawParticleCircle( futureTargetPos, 8.0f, Vec2f_zero, color, 0, 4.0f);
	}

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