// small artillery

#include "SpaceshipGlobal.as"
#include "Hitters.as";
#include "BarrierCommon.as";
#include "CommonFX.as";

Random _ray_shot_r(68127);

const f32 damage = 0.1f;

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
	Vec2f thisVelNorm = thisVel;
	thisVelNorm.Normalize();
	Vec2f rayRange = thisVelNorm * this.get_f32(shotLifetimeString);
	
	f32 travelDist = rayRange.getLength();
	Vec2f futurePos = thisPos + rayRange;

	const bool is_client = isClient();
	const bool firstTick = this.get_bool(firstTickString) || (is_client && this.get_bool(clientFirstTickString));

	if (!firstTick) return;
	this.set_bool(firstTickString, false);
	
	if (is_client)
	{
		Vec2f thisOldPos = this.get_Vec2f(oldPosString);
		this.set_Vec2f(oldPosString, thisPos);

		doMuzzleFlash(thisPos, thisVel);
		this.set_bool(clientFirstTickString, false);
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

			if (b.getHealth() >= b.getInitialHealth())
			{ continue; }

			if (isServer() && b.hasTag("hull"))
			{
				b.server_Heal(damage);
			}
			break;
		}
	}
	else if (hitWall) //if there was no hit, but there is a wall, move bullet there and die
	{
		thisPos = futurePos;
		if (is_client)
		{
			Sound::Play("dig_dirt2.ogg", futurePos, 1.5f + (0.2f * _ray_shot_r.NextFloat()), 1.0f + (0.2f * _ray_shot_r.NextFloat()));
		}
	}

	//this.set_Vec2f(oldPosString, thisPos);
	doTrailParticles(thisPos, this.getPosition());
}

void onDie( CBlob@ this )
{
	//Vec2f thisOldPos = this.get_Vec2f(oldPosString);
	//Vec2f thisPos = this.getPosition();

	//doTrailParticles(thisOldPos, thisPos); //do one last trail particle on death
	//this.set_Vec2f(oldPosString, thisPos);
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

	u8 colorValue = 200.0f * _ray_shot_r.NextFloat();
	SColor color = SColor(255,colorValue,255,colorValue);

	for(int i = 0; i <= steps; i++)
   	{
		if (_ray_shot_r.NextFloat() > 0.5f) //percentage chance of spawned particles
		{ continue; }

		Vec2f pPos = (trailNorm * i) + oldPos;

    	CParticle@ p = ParticlePixelUnlimited(pPos, Vec2f_zero, color, true);
    	if(p !is null)
    	{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 8;
			p.timeout = 1;
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

	const int particleNum = 2; //particle amount

	for(int i = 0; i < particleNum; i++)
   	{
		Vec2f pPos = thisPos;
		Vec2f pVel = flashNorm;
		pVel *= 0.2f + _ray_shot_r.NextFloat();

		f32 randomDegrees = 20.0f;
		randomDegrees *= 1.0f - (2.0f * _ray_shot_r.NextFloat());
		pVel.RotateByDegrees(randomDegrees);
		pVel *= 2.5; //final speed multiplier

		f32 pAngle = 360.0f * _ray_shot_r.NextFloat();

		CParticle@ p = ParticleAnimated("MissileFire2.png", pPos, pVel, pAngle, 1.0f, 2, 0, true);
    	if(p !is null)
    	{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 8;
			p.timeout = 10;
		}
	}
	
	Sound::Play("BasicShotSound.ogg", thisPos, 0.3f , 1.3f + (0.1f * _ray_shot_r.NextFloat()));
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	int thisTeamNum = this.getTeamNum();
	int blobTeamNum = blob.getTeamNum();

	return
	(
		(
			thisTeamNum == blobTeamNum &&
			blob.hasTag("hull")
		)
		||
		(
			blob.hasTag("barrier")
		)
	) && !this.get_bool("expired");
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f collisionPos )
{
	if ((this == null || blob == null) && solid)
	{
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
}