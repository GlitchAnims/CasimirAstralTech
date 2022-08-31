// small artillery

#include "SpaceshipGlobal.as"
#include "Hitters.as";
#include "BarrierCommon.as";
#include "CommonFX.as";

Random _shot_r(35400);

const f32 damage = 2.0f;

void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(2);
	this.set_f32(shotLifetimeString, 1.0f); //SpaceshipGlobal.as

	CShape@ shape = this.getShape();
	if (shape != null)
	{
		shape.getConsts().mapCollisions = true;
		shape.getConsts().bullet = true;
		shape.getConsts().net_threshold_multiplier = 4.0f;
		shape.SetGravityScale(0.0f);
	}

	this.Tag("projectile");

	this.set_Vec2f(oldPosString, Vec2f_zero); //SpaceshipGlobal.as
	this.set_bool(firstTickString, true); //SpaceshipGlobal.as
	this.set_bool(clientFirstTickString, true); //SpaceshipGlobal.as

	this.getSprite().SetFrame(0);
	this.SetMapEdgeFlags(CBlob::map_collide_up | CBlob::map_collide_down | CBlob::map_collide_sides);
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap(); //standard map check
	if (map is null)
	{ return; }

	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	
	f32 travelDist = thisVel.getLength();
	Vec2f futurePos = thisPos + thisVel;

	const bool is_client = isClient();
	const bool firstTick = this.get_bool(firstTickString) || (is_client && this.get_bool(clientFirstTickString));
	if (firstTick)
	{
		if (is_client)
		{
			doMuzzleFlash(thisPos, thisVel);
			this.set_bool(clientFirstTickString, false);
		}
		if (isServer()) //bullet range moderation
		{
			float lifeTime = this.get_f32(shotLifetimeString);
			this.server_SetTimeToDie(lifeTime);
		}
		this.set_bool(firstTickString, false);
	}
	if (is_client)
	{
		Vec2f thisOldPos = this.get_Vec2f(oldPosString);
		doTrailParticles(thisOldPos, thisPos);
		this.set_Vec2f(oldPosString, thisPos);
		CSprite@ thisSprite = this.getSprite();
		if (thisSprite != null)
		{
			thisSprite.ResetTransform();
			thisSprite.RotateBy(-thisVel.getAngleDegrees(), Vec2f_zero);
		}
	}

	Vec2f wallPos = Vec2f_zero;
	bool hitWall = map.rayCastSolidNoBlobs(thisPos, futurePos, wallPos); //if there's a wall, end the travel early
	if (hitWall)
	{
		futurePos = wallPos;
		Vec2f fixedTravel = futurePos - thisPos;
		travelDist = fixedTravel.getLength();
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
			this.server_Hit(b, thisPos, thisVel, damage, Hitters::explosion, false);
			this.server_Die();
			return;
		}
	}
	
	if (hitWall) //if there was no hit, but there is a wall, move bullet there and die
	{
		this.setPosition(futurePos);
		this.server_Die();
	}
}

void onDie( CBlob@ this )
{
	Vec2f thisOldPos = this.get_Vec2f(oldPosString);
	Vec2f thisPos = this.getPosition();

	doTrailParticles(thisOldPos, thisPos); //do one last trail particle on death
	this.set_Vec2f(oldPosString, thisPos);
	makeHitEffect(thisPos);
}

void doTrailParticles(Vec2f oldPos = Vec2f_zero, Vec2f newPos = Vec2f_zero)
{
	if (!isClient())
	{ return; }

	if (oldPos == Vec2f_zero || newPos == Vec2f_zero)
	{ return; }

	Vec2f trailVec = newPos - oldPos;
	int steps = trailVec.getLength();
	Vec2f trailNorm = trailVec;
	trailNorm.Normalize();

	for(int i = 0; i <= steps; i++)
   	{
		if (_shot_r.NextFloat() > 0.2f) //percentage chance of spawned particles
		{ continue; }

		Vec2f pPos = (trailNorm * i) + oldPos;
		f32 pAngle = 360.0f * _shot_r.NextFloat();

    	CParticle@ p = ParticleAnimated("MissileFire1.png", pPos, Vec2f_zero, pAngle, 0.5f, 1, 0, true);
    	if(p !is null)
    	{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 11;
			p.timeout = 10;
		}
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

	const int particleNum = 3; //particle amount

	for(int i = 0; i < particleNum; i++)
   	{
		Vec2f pPos = thisPos;
		Vec2f pVel = flashNorm;
		pVel *= 0.2f + _shot_r.NextFloat();

		f32 randomDegrees = 20.0f;
		randomDegrees *= 1.0f - (2.0f * _shot_r.NextFloat());
		pVel.RotateByDegrees(randomDegrees);
		pVel *= 2.5; //final speed multiplier

		f32 pAngle = 360.0f * _shot_r.NextFloat();

		CParticle@ p = ParticleAnimated("RocketFire3.png", pPos, pVel, pAngle, 1.5f, 2, 0, true);
    	if(p !is null)
    	{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 12;
			p.timeout = 10;
		}
	}
	
	Sound::Play("tachyon_launch.ogg", thisPos, 1.0f , 0.9f + (0.2f * _shot_r.NextFloat()));
}

void makeHitEffect(Vec2f thisPos = Vec2f_zero)
{
	if(!isClient() || thisPos == Vec2f_zero)
	{return;}

	Sound::Play("tachyon_hit.ogg", thisPos, 1.0f + (0.2f * _shot_r.NextFloat()), 0.9f + (0.2f * _shot_r.NextFloat()));

    const int particleNum = 15; //particle amount

	for(int i = 0; i < particleNum; i++)
   	{
		Vec2f pPos = thisPos;
		Vec2f pVel = Vec2f(1.0f, 0);

		float randomDegrees = 360.0f * _shot_r.NextFloat();
		pVel.RotateByDegrees(randomDegrees);
		pVel *= 0.2f + _shot_r.NextFloat(); //final speed multiplier

		float pAngle = 360.0f * _shot_r.NextFloat(); // sprite angle

		CParticle@ p = ParticleAnimated("MissileFire1.png", pPos, pVel, pAngle, 1.0f, 2, 0, true);
    	if(p !is null)
    	{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 12;
			p.timeout = 10;
		}
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
	Vec2f thisPos = this.getPosition();
	if ((this == null || blob == null) && solid)
	{
		this.server_Die();
		return;
	}

	if (!doesCollideWithBlob(this, blob))
	{ return; }

	Vec2f thisVel = this.getVelocity();

	if (blob.hasTag("barrier"))
	{
		if(doesBypassBarrier(blob, collisionPos, thisVel))
		{ return; }
	}

	this.server_Hit(blob, thisPos, thisVel, damage, Hitters::cata_stones, false);
	this.server_Die();
}