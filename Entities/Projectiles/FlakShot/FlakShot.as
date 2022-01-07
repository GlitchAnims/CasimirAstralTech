// small artillery

#include "SpaceshipGlobal.as"
#include "Hitters.as";
#include "BarrierCommon.as";
#include "CommonFX.as";

Random _flak_shot_r(13444);

const f32 damage = 0.5f;
const f32 radius = 24.0f;

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

	if (this.get_bool(firstTickString))
	{
		if (is_client)
		{
			doMuzzleFlash(thisPos, thisVel);
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

			this.server_Die();
			return;
		}
	}
	
	if (hitWall) //if there was no hit, but there is a wall, move bullet there and die
	{
		this.server_Die();
	}
}

void onDie( CBlob@ this )
{
	Vec2f thisOldPos = this.get_Vec2f(oldPosString);
	Vec2f thisPos = this.getPosition();

	makeFlakEffect(thisPos); //flak boom
	makeFlakDamage(this, thisPos); //flak AOE

	this.set_Vec2f(oldPosString, thisPos);
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

	for(int i = 0; i <= steps; i += 2)
   	{
		if (_flak_shot_r.NextFloat() > 0.5f) //percentage chance of spawned particles
		{ continue; }

		Vec2f pPos = (trailNorm * i) + oldPos;
		f32 pAngle = 360.0f * _flak_shot_r.NextFloat();

    	CParticle@ p = ParticleAnimated("GenericSmoke4.png", pPos, Vec2f_zero, pAngle, 0.4f, 1, 0, true);
    	if(p !is null)
    	{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 8;
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

	const int particleNum = 4; //particle amount

	for(int i = 0; i < particleNum; i++)
   	{
		Vec2f pPos = thisPos;
		Vec2f pVel = flashNorm;
		pVel *= 0.2f + _flak_shot_r.NextFloat();

		f32 randomDegrees = 20.0f;
		randomDegrees *= 1.0f - (2.0f * _flak_shot_r.NextFloat());
		pVel.RotateByDegrees(randomDegrees);
		pVel *= 2.5; //final speed multiplier

		f32 pAngle = 360.0f * _flak_shot_r.NextFloat();

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
	
	Sound::Play("BasicShotSound.ogg", thisPos, 0.3f , 1.3f + (0.1f * _flak_shot_r.NextFloat()));
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
			blob.hasTag("barrier") &&
			blob.get_bool("active")
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

	this.server_Die();
}

void makeFlakEffect(Vec2f thisPos = Vec2f_zero)
{
	if(!isClient() || thisPos == Vec2f_zero)
	{return;}

	u16 particleNum = XORRandom(5)+5;

	Sound::Play("Bomb.ogg", thisPos, 0.8f, 0.8f + (0.4f * _flak_shot_r.NextFloat()) );

	for (int i = 0; i < particleNum; i++)
    {
        Vec2f pOffset(_flak_shot_r.NextFloat() * radius, 0);
        pOffset.RotateBy(_flak_shot_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated("GenericSmoke1.png", 
									thisPos + pOffset, 
									Vec2f_zero, 
									_flak_shot_r.NextFloat() * 360.0f, 
									0.5f + (_flak_shot_r.NextFloat() * 0.5f), 
									XORRandom(3)+1, 
									0.0f, 
									false );
									
        if(p is null) continue; //bail if we stop getting particles
		
    	p.collides = false;
		p.Z = 200.0f;
		p.lighting = false;
    }
}

void makeFlakDamage(CBlob@ this, Vec2f thisPos = Vec2f_zero)
{
	if (!isServer() || thisPos == Vec2f_zero)
	{ return; }

	CMap@ map = getMap(); //standard map check
	if (map is null)
	{ return; }

	int teamNum = this.getTeamNum();

	CBlob@[] blobsInRadius;
	map.getBlobsInRadius(thisPos, radius, @blobsInRadius);
	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		CBlob@ b = blobsInRadius[i];
		if (b is null)
		{ continue; }

		if (b.getTeamNum() == teamNum || !b.hasTag("hull"))
		{ continue; }

		Vec2f bPos = b.getPosition();
		Vec2f targetVec = bPos - thisPos;
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
				
				if (b2.getTeamNum() != teamNum && b2.hasTag("barrier") && b2.get_bool("active"))
				{ 
					targetIsValid = false;
					break;
				}
			}
		} //hitscan loop end

		if (targetIsValid)
		{
			this.server_Hit(b, thisPos, Vec2f_zero, b.hasTag(smallTag) ? damage : 0.1f, Hitters::arrow, false);
		}
	} //radius loop end
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ targetBlob, u8 customData )
{
	if (!isClient())
	{ return; }

	if (targetBlob.hasTag("hull"))
	{
		Sound::Play("dry_hit.ogg", worldPoint, 1.0f + (0.2f * _flak_shot_r.NextFloat()), 1.0f + (0.2f * _flak_shot_r.NextFloat()));
	}
	else if (targetBlob.hasTag("flesh"))
	{
		Sound::Play("ArrowHitFlesh.ogg", worldPoint, 2.0f + (0.1f * _flak_shot_r.NextFloat()), 1.2f );
	}
}