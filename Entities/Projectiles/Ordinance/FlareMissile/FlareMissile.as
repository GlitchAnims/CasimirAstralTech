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
const f32 radius = 32.0f;

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

	this.server_SetTimeToDie(2);
	this.set_f32(shotLifetimeString, 1.0f); //SpaceshipGlobal.as
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

	this.set_bool(firstTickString, true); //SpaceshipGlobal.as

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

	if (this.get_bool(firstTickString))
	{
		if (is_client)
		{
			doMuzzleFlash(thisPos, thisVel);
		}
		if (is_server) //bullet range moderation
		{
			float lifeTime = this.get_f32(shotLifetimeString);
			this.server_SetTimeToDie(lifeTime);
		}
		this.setAngleDegrees(-thisVel.getAngleDegrees());
		this.set_bool(firstTickString, false);
	}
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

	doThrustParticles(thisPos, -thrustNorm*2.0f); //exhaust particles - Client only
*/	
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

void onDie( CBlob@ this )
{
	Vec2f thisPos = this.getPosition();

	makeMissileEffect(thisPos); //boom effect
	makeMissileDamage(this, thisPos); //AOE damage
}

void doThrustParticles(Vec2f pPos = Vec2f_zero, Vec2f pVel = Vec2f_zero)
{
	if (!isClient())
	{ return; }

	if (pPos == Vec2f_zero || pVel == Vec2f_zero)
	{ return; }

	if (_aa_missile_r.NextFloat() > 0.8f) //percentage chance of spawned particles
	{ return; }

	f32 pAngle = 360.0f * _aa_missile_r.NextFloat();
	pVel.RotateByDegrees( 20.0f * (1.0f - (2.0f * _aa_missile_r.NextFloat())) );

   	CParticle@ p = ParticleAnimated("GenericSmoke4.png", pPos, pVel, pAngle, 0.4f, 1, 0, true);
   	if(p !is null)
   	{
		p.fastcollision = true;
		p.gravity = Vec2f_zero;
		p.bounce = 0;
		p.Z = 8;
		p.timeout = 10;
	}

}

void doMuzzleFlash(Vec2f thisPos = Vec2f_zero, Vec2f flashVec = Vec2f_zero)
{
	if (!isClient())
	{ return; }

	if (thisPos == Vec2f_zero || flashVec == Vec2f_zero)
	{ return; }
	
	Vec2f flashNorm = flashVec;
	flashNorm.Normalize();

	const int particleNum = 4; //particle amount

	for(int i = 0; i < particleNum; i++)
   	{
		Vec2f pPos = thisPos;
		Vec2f pVel = flashNorm;
		pVel *= 0.2f + _aa_missile_r.NextFloat();

		f32 randomDegrees = 20.0f;
		randomDegrees *= 1.0f - (2.0f * _aa_missile_r.NextFloat());
		pVel.RotateByDegrees(randomDegrees);
		pVel *= 2.5; //final speed multiplier

		f32 pAngle = 360.0f * _aa_missile_r.NextFloat();

		CParticle@ p = ParticleAnimated("GenericBlast6.png", pPos, pVel, pAngle, 0.5f, 1, 0, true);
    	if(p !is null)
    	{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 8;
			p.timeout = 10;
		}
	}
	
	Sound::Play("BasicShotSound.ogg", thisPos, 0.3f , 1.3f + (0.1f * _aa_missile_r.NextFloat()));
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

void makeMissileEffect(Vec2f thisPos = Vec2f_zero)
{
	if(!isClient() || thisPos == Vec2f_zero)
	{return;}

	u16 particleNum = XORRandom(5)+5;

	Sound::Play("Bomb.ogg", thisPos, 0.8f, 0.8f + (0.4f * _aa_missile_r.NextFloat()) );

	for (int i = 0; i < particleNum; i++)
    {
        Vec2f pOffset(_aa_missile_r.NextFloat() * radius, 0);
        pOffset.RotateBy(_aa_missile_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated("GenericSmoke1.png", 
									thisPos + pOffset, 
									Vec2f_zero, 
									_aa_missile_r.NextFloat() * 360.0f, 
									0.5f + (_aa_missile_r.NextFloat() * 0.5f), 
									XORRandom(3)+1, 
									0.0f, 
									false );
									
        if(p is null) continue; //bail if we stop getting particles
		
    	p.collides = false;
		p.Z = 200.0f;
		p.lighting = false;
    }
}

void makeMissileDamage(CBlob@ this, Vec2f thisPos = Vec2f_zero)
{
	if (!isServer() || thisPos == Vec2f_zero)
	{ return; }

	CMap@ map = getMap(); //standard map check
	if (map is null)
	{ return; }

	int teamNum = this.getTeamNum();

	CBlob@[] blobsInRadius;
	map.getBlobsInRadius(thisPos, radius, @blobsInRadius); //tent aura push
	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		CBlob@ b = blobsInRadius[i];
		if (b is null)
		{ continue; }

		if (b.getTeamNum() == teamNum || b.hasTag("dead"))
		{ continue; }

		if (b.hasTag("barrier"))
		{
			if (b.get_bool("active"))
			{
				this.server_Hit(b, thisPos, Vec2f_zero, damage, Hitters::explosion, false);
			}
			continue;
		}

		Vec2f targetPos = b.getPosition();
		Vec2f targetVec = targetPos - thisPos;
		float targetDist = targetVec.getLength();

		bool targetIsValid = true;
		HitInfo@[] hitInfos;
		bool hasHit = map.getHitInfosFromRay(thisPos, -targetVec.getAngleDegrees(), targetDist, this, @hitInfos);
		if (hasHit) //hitray scan
		{
			for (uint i = 0; i < hitInfos.length; i++)
			{
				HitInfo@ hi = hitInfos[i];
				CBlob@ b2 = hi.blob;
				if (b2 == null) // check
				{ continue; }
				
				if (b2.getTeamNum() != teamNum && b2.hasTag("barrier") && !doesBypassBarrier(b2, hi.hitpos, targetVec))
				{ 
					targetIsValid = false;
					break;
				}
			}
		} //hitscan loop end

		if (targetIsValid)
		{
			this.server_Hit(b, targetPos, Vec2f_zero, damage, Hitters::explosion, false);
		}
	} //radius loop end
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ targetBlob, u8 customData )
{
	if (!isClient())
	{ return; }

	if (targetBlob.hasTag("hull"))
	{
		Sound::Play("dry_hit.ogg", worldPoint, 1.0f + (0.2f * _aa_missile_r.NextFloat()), 1.0f + (0.2f * _aa_missile_r.NextFloat()));
	}
	else if (targetBlob.hasTag("flesh"))
	{
		Sound::Play("ArrowHitFlesh.ogg", worldPoint, 2.0f + (0.1f * _aa_missile_r.NextFloat()), 1.2f );
	}
}