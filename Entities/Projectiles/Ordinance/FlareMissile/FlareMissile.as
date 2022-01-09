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
const f32 radius = 24.0f;

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

	MissileInfo@ missile;
	if (!this.get( "missileInfo", @missile )) 
	{ return; }

	u16 targetBlobID = this.get_u16(targetNetIDString);
	CBlob@ targetBlob = getBlobByNetworkID(targetBlobID);
	if ( targetBlobID == 0 || targetBlob == null)
	{
		if (is_server)
		{
			CBlob@[] targetCandidates;
			CBlob@[] blobsInRadius;
			map.getBlobsInRadius(thisPos, searchRadius, @blobsInRadius); //possible enemies in radius
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob@ b = blobsInRadius[i];
				if (b is null)
				{ continue; }

				if (b.getTeamNum() == teamNum)
				{ continue; }

				if ((b.hasTag(smallTag) || b.hasTag(mediumTag)) && !b.hasTag("dead")) //only small and medium ships
				{ 
					targetCandidates.push_back(b); //into the list
				}
			}
			u16 candidatesLength = targetCandidates.length();
			if (candidatesLength > 0)
			{
				CBlob@ selectedCandidate = targetCandidates[XORRandom(candidatesLength)]; //selects one from list

				this.set_u16(targetNetIDString, selectedCandidate.getNetworkID());
				this.Sync(targetNetIDString, true);
			}
		}

		turnOffAllThrust( missile );
		return;
	}

	//homing logic
	f32 thisReducedSpeed = missile.max_speed*0.5f; //arbitrary travel speed. TODO actual homing logic

	Vec2f targetPos = targetBlob.getPosition();
	Vec2f bVel = targetBlob.getVelocity() - (thisVel); //compensates for missile speed

	Vec2f targetVec = targetPos - thisPos;
	f32 targetDist = targetVec.getLength(); //distance to target

	if (targetDist > searchRadius) //lose target logic
	{
		u32 hasTargetTicks = this.get_u32(hasTargetTicksString);
		if (hasTargetTicks < missile.lose_target_ticks)
		{
			this.set_u32(hasTargetTicksString, hasTargetTicks + 1); //up by one
		}
		else //set target to null and stop the code
		{
			this.set_u16(targetNetIDString, 0);
			if (is_server)
			{ this.Sync(targetNetIDString, true); }
			
			this.set_u32(hasTargetTicksString, 0);
			return;
		}
	}
	else //resets lose target timer if in range
	{
		this.set_u32(hasTargetTicksString, 0); 
		if (is_server)
		{ this.Sync(hasTargetTicksString, true); }
	}

	if (is_server) //server only detonation
	{
		if (targetDist < radius*0.8f) //if closer than 80% of explosion radius, detonate.
		{
			this.server_Die();
			return;
		}
	}
	
	f32 travelTicks = targetDist / thisReducedSpeed; //theoretical ticks required to get to the target (again, TODO)
	Vec2f futureTargetPos = targetPos + (bVel*travelTicks); //matches future target pos with travel time
	
	//this block of code re-does the calculation to be more exact
	targetVec = futureTargetPos - thisPos;
	targetDist = targetVec.getLength();
	travelTicks = targetDist / thisReducedSpeed;
	futureTargetPos = targetPos + (bVel*travelTicks);

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

	if (!is_client)
	{ return; }
	const f32 gameTimeVariation = gameTime + this.getNetworkID();
	const f32 targetSquareAngle = (gameTimeVariation * 10.1f) % 360;
	
	doThrustParticles(thisPos, -thrustNorm*2.0f); //exhaust particles
	
	f32 targetAngle = targetBlob.getAngleDegrees();
	//client UI and sounds
	CPlayer@ ownerPlayer = this.getDamageOwnerPlayer();
	if (ownerPlayer != null && ownerPlayer.isMyPlayer()) //player who launched missiles only
	{
		makeBlobTriangle(targetPos, targetAngle, Vec2f(4.0f, 3.0f)); //enemy triangle
		makeTargetSquare(futureTargetPos, targetSquareAngle, Vec2f(2.5f, 2.5f), 2.0f, 1.0f); //target acquired square
	}
	CPlayer@ targetPlayer = targetBlob.getPlayer();
	if (targetPlayer != null && targetPlayer.isMyPlayer()) //targeted player only (if any)
	{
		makeTargetSquare(futureTargetPos, targetSquareAngle, Vec2f(2.5f, 2.5f), 2.0f, 1.0f, redConsoleColor); //target acquired square
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