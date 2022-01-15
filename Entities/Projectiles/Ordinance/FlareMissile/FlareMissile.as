// small artillery

#include "SpaceshipGlobal.as"
#include "Hitters.as"
#include "BarrierCommon.as"
#include "CommonFX.as"
#include "ComputerCommon.as"
#include "OrdinanceCommon.as"

Random _aa_missile_r(12231);

const f32 damage = 0.5f;
const f32 searchRadius = 128.0f;
const f32 radius = 64.0f;

void onInit(CBlob@ this)
{
	MissileInfo missile;
	missile.main_engine_force 			= AAMissileParams::main_engine_force;
//	missile.secondary_engine_force 		= AAMissileParams::secondary_engine_force;
//	missile.rcs_force 					= AAMissileParams::rcs_force;
//	missile.ship_turn_speed 			= AAMissileParams::ship_turn_speed;
	missile.max_speed 					= AAMissileParams::max_speed;
	missile.lose_target_ticks 			= AAMissileParams::lose_target_ticks;
	this.set("missileInfo", @missile);

	this.server_SetTimeToDie(10);
	this.set_u32(hasTargetTicksString, 0);
	this.set_u16(targetNetIDString, 0);

	CShape@ shape = this.getShape();
	if (shape != null)
	{
		shape.getConsts().mapCollisions = true;
		shape.getConsts().bullet = true;
		shape.getConsts().net_threshold_multiplier = 4.0f;
		shape.SetGravityScale(0.0f);
	}

	this.Tag("projectile");
	this.Tag("hull");

	this.getSprite().SetFrame(0);
	this.SetMapEdgeFlags(CBlob::map_collide_up | CBlob::map_collide_down | CBlob::map_collide_sides);
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap(); //standard map check
	if (map is null)
	{ return; }

	const u32 gameTime = getGameTime();

	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	int teamNum = this.getTeamNum();

	f32 travelDist = thisVel.getLength();
	Vec2f futurePos = thisPos + thisVel;

	const bool is_client = isClient();
	const bool is_server = isServer();

/*
	HitInfo@[] hitInfos;
	bool hasHit = map.getHitInfosFromRay(thisPos, -thisVel.getAngleDegrees(), travelDist, this, @hitInfos);
	if (hasHit) //hitray scan
	{
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;
			if (b == null) // check
			{ continue; }
			
			if (!doesCollideWithBlob(this, b))
			{ continue; }

			thisPos = hi.hitpos;

			if (b.hasTag("barrier"))
			{
				if(doesBypassBarrier(b, thisPos, thisVel))
				{ continue; }
			}

			this.setPosition(thisPos);
			this.server_Die();
			return;
		}
	}
*/
	MissileInfo@ missile;
	if (!this.get( "missileInfo", @missile )) 
	{ return; }
/*
	Vec2f thrustVec = futureTargetPos - thisPos;
	Vec2f thrustNorm = thrustVec;
	thrustNorm.Normalize();
	f32 thrustAngle = thrustNorm.getAngleDegrees();

	Vec2f newVel = thisVel + (thrustNorm * missile.main_engine_force);

	f32 maxSpeed = missile.max_speed;
	if (maxSpeed != 0 && newVel.getLength() > maxSpeed) //max speed logic - 0 means no cap
	{
		newVel.Normalize();
		newVel *= maxSpeed;
	}

	this.setVelocity(newVel);
	this.setAngleDegrees(-thrustAngle);
	missile.forward_thrust = true;
*/	
	if (!missile.forward_thrust)
	{
		missile.forward_thrust = true;
	}

	const u16 thisNetID = this.getNetworkID();
	const f32 gameTimeVariation = gameTime + thisNetID;
	if (gameTimeVariation % 30 == 0) //Interference, Once a second
	{
		CBlob@[] blobsInRadius;
		map.getBlobsInRadius(thisPos, radius, @blobsInRadius);
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob@ b = blobsInRadius[i];
			if (b is null)
			{ continue; }

			if (b.getTeamNum() == teamNum) //enemies only
			{ continue; }

			if (b.hasTag("player") && !b.hasTag("dead"))
			{
				if (!b.isMyPlayer())
				{ continue; }
				f32 targetDist = this.getDistanceTo(b);
				f32 percentage = 1.0f - (targetDist/radius);

				if (b.get_f32(interferenceMultString) < percentage) //inflict interference only if below threshold
				{
					b.set_f32(interferenceMultString, percentage);
				}
			}
			else if (b.hasTag("projectile"))
			{
				b.set_u16(targetNetIDString, thisNetID);
			}
		} //for loop end
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	int thisTeamNum = this.getTeamNum();
	int blobTeamNum = blob.getTeamNum();

	return
	(
		(
			thisTeamNum != blobTeamNum ||
			blob.hasTag("dead")
		)
		&&
		(
			blob.hasTag("flesh") ||
			blob.hasTag("hull") ||
			blob.hasTag("barrier")
		)
	);
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f collisionPos )
{
	if ((this == null || blob == null) && solid)
	{
		this.server_Die();
		return;
	}

	if (!doesCollideWithBlob(this, blob))
	{ return; }

	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();

	if (blob.hasTag("barrier"))
	{
		if(doesBypassBarrier(blob, collisionPos, thisVel))
		{ return; }
	}

	this.server_Die();
}