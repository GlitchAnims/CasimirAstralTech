// huk

#include "SpaceshipGlobal.as"
#include "GrappleCommon.as"
#include "BarrierCommon.as"

const float radius = 16.0f;

void onInit(CBlob@ this)
{
	//this.server_SetTimeToDie(2);

	this.set_bool(firstTickString, true); //SpaceshipGlobal.as
	this.set_bool(clientFirstTickString, true); //SpaceshipGlobal.as

	resetHook(this);

	this.getShape().SetGravityScale(0.0f);
	this.getSprite().SetFrame(0);

	this.addCommandID(hookSyncCommandID);
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap(); //standard map check
	if (map is null) return;

	CBlob@ ownerBlob = getBlobByNetworkID(this.get_u16("ownerBlobID"));
	if (ownerBlob == null || !ownerBlob.get_bool("shifting"))
	{
		this.server_Die();
		return;
	}

	const bool isOwnerShifting = ownerBlob.get_bool("shifting");

	const u32 gameTime = getGameTime();

	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	float thisVelAngle = thisVel.getAngleDegrees();
	int teamNum = this.getTeamNum();

	f32 travelDist = thisVel.getLength();
	Vec2f futurePos = thisPos + thisVel;

	const bool is_client = isClient();
	const bool is_server = isServer();

	const bool firstTick = this.get_bool(firstTickString) || (is_client && this.get_bool(clientFirstTickString));
	if (firstTick)
	{
		if (is_client)
		{
			doMuzzleFlash(thisPos, thisVel);
			this.set_bool(clientFirstTickString, false);
		}
		//this.setAngleDegrees(-thisVelAngle);
		this.set_bool(firstTickString, false);
	}

	float newAngle = -thisVelAngle;

	u16 hookTargetNetID = this.get_u16(hookTargetNetIDString);
	CBlob@ hookTargetBlob = getBlobByNetworkID(hookTargetNetID);
	
	if (this.get_bool(hookIsAttachedBoolString))
	{
		if (hookTargetNetID == 0 || hookTargetBlob == null || !isOwnerShifting) resetHook(this);
		else
		{
			Vec2f hookTargetPos = hookTargetBlob.getPosition();
			Vec2f hookTargetVel = hookTargetBlob.getVelocity();
			float hookTargetAngle = hookTargetBlob.getAngleDegrees();

			Vec2f stuckHookOffset = this.get_Vec2f(hookStuckOffsetString);
			float hookOffsetAngle = this.get_f32(hookStuckOffsetAngleString);
			float hookAngle = this.get_f32(hookStuckAngleString);

			stuckHookOffset.RotateByDegrees(hookTargetAngle - hookOffsetAngle);
			this.setPosition(hookTargetPos+stuckHookOffset);
			this.setVelocity(hookTargetVel);
			newAngle = hookTargetAngle + hookAngle;
		}
	}
	else if (isOwnerShifting) // only stick to things if shifting
	{
		HitInfo@[] hitInfos;
		bool hasHit = map.getHitInfosFromRay(thisPos, -thisVelAngle, travelDist, this, @hitInfos);
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

				Vec2f hitPos = hi.hitpos;
				Vec2f bPos = b.getPosition();
				float bAngle = b.getAngleDegrees();

				Vec2f bHitVec = bPos - hitPos;
				float hitAngle = bHitVec.getAngleDegrees();

				if (b.hasTag("barrier"))
				{
					if(doesBypassBarrier(b, hitPos, thisVel))
					{ continue; }
					else
					{
						float angleDiff = (hitAngle+180.0f) - thisVelAngle;
						angleDiff += angleDiff > 180 ? -360 : angleDiff < -180 ? 360 : 0;

						Vec2f bounceVel = thisVel;
						bounceVel.RotateByDegrees(-angleDiff*2);
						this.setVelocity(-bounceVel);
						this.setPosition(hitPos);
						break;
					}
				}

				this.setPosition(hitPos);

				this.set_bool(hookIsAttachedBoolString, true);
				this.set_u16(hookTargetNetIDString, b.getNetworkID());
				
				this.set_Vec2f(hookStuckOffsetString, -bHitVec);

				this.set_f32(hookStuckOffsetAngleString, bAngle);

				float angleDiff = newAngle - bAngle;
				angleDiff += angleDiff > 180 ? -360 : angleDiff < -180 ? 360 : 0;
				this.set_f32(hookStuckAngleString, angleDiff);
				return;
			}
		}
	}
	this.setAngleDegrees(newAngle);

	const u32 gameTimeVariation = gameTime + this.getNetworkID();
	if (is_server && gameTimeVariation % 30 == 0) syncHook(this); // once a second, sync to client
	
	if (!is_client) return; // client only beyond this point
	//const f32 targetSquareAngle = (gameTimeVariation * 10.1f) % 360;
}

void resetHook( CBlob@ this )
{
	this.set_bool(hookIsAttachedBoolString, false);
	this.set_u16(hookTargetNetIDString, 0);

	this.set_Vec2f(hookStuckOffsetString, Vec2f_zero);
	this.set_f32(hookStuckOffsetAngleString, 0.0f);
	this.set_f32(hookStuckAngleString, 0.0f);
}

void syncHook( CBlob@ this )
{
	CBitStream params;
	bool hookIsAttached = this.get_bool(hookIsAttachedBoolString);
	params.write_bool(hookIsAttached);

	if (hookIsAttached)
	{
		params.write_u16(this.get_u16(hookTargetNetIDString));

		params.write_Vec2f(this.get_Vec2f(hookStuckOffsetString));
		params.write_f32(this.get_f32(hookStuckOffsetAngleString));
		params.write_f32(this.get_f32(hookStuckAngleString));
	}

	this.SendCommand(this.getCommandID(hookSyncCommandID), params);
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (this == null) return;
	
	if (isClient() && cmd == this.getCommandID(hookSyncCommandID))
	{
		bool hookIsAttached;
		if (!params.saferead_bool(hookIsAttached)) return;

		if (hookIsAttached)
		{
			u16 hookTargetNetID;
			Vec2f stuckHookOffset;
			float stuckHookOffsetAngle;
			float stuckHookAngleString;

			if (!params.saferead_u16(hookTargetNetID) || 
			!params.saferead_Vec2f(stuckHookOffset) || 
			!params.saferead_f32(stuckHookOffsetAngle) || 
			!params.saferead_f32(stuckHookAngleString)) return;

			this.set_u16(hookTargetNetIDString, hookTargetNetID);
			this.set_Vec2f(hookStuckOffsetString, stuckHookOffset);
			this.set_f32(hookStuckOffsetAngleString, stuckHookOffsetAngle);
			this.set_f32(hookStuckAngleString, stuckHookAngleString);
		}
		else
		{
			resetHook(this);
		}
	}

	//else if (cmd == this.getCommandID(homing_target_update_ID)) // resets lose target timer for all clients
}

void onDie( CBlob@ this )
{
	Vec2f thisPos = this.getPosition();

	makeMissileEffect(thisPos); //boom effect
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
		pVel *= 0.2f + _grapple_r.NextFloat();

		f32 randomDegrees = 20.0f;
		randomDegrees *= 1.0f - (2.0f * _grapple_r.NextFloat());
		pVel.RotateByDegrees(randomDegrees);
		pVel *= 2.5; //final speed multiplier

		f32 pAngle = 360.0f * _grapple_r.NextFloat();

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
	
	Sound::Play("BasicShotSound.ogg", thisPos, 0.3f , 1.3f + (0.1f * _grapple_r.NextFloat()));
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	int thisTeamNum = this.getTeamNum();
	int blobTeamNum = blob.getTeamNum();

	if (this.get_bool(hookIsAttachedBoolString)) return false;

	return
	(
		(
			thisTeamNum != blobTeamNum ||
			blob.hasTag("dead")
		)
		&&
		(
			blob.hasTag("flesh") ||
			(blob.hasTag("hull") && blob.get_u8(shipSizeString) >= _size_medium) ||
			blob.hasTag("barrier")
		)
	);
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f collisionPos )
{
	if ((this == null || blob == null) && solid)
	{
		return;
	}

}

void makeMissileEffect(Vec2f thisPos = Vec2f_zero)
{
	if(!isClient() || thisPos == Vec2f_zero)
	{return;}

	u16 particleNum = XORRandom(5)+5;

	Sound::Play("Bomb.ogg", thisPos, 0.8f, 0.8f + (0.4f * _grapple_r.NextFloat()) );

	for (int i = 0; i < particleNum; i++)
    {
        Vec2f pOffset(_grapple_r.NextFloat() * radius, 0);
        pOffset.RotateBy(_grapple_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated("GenericSmoke1.png", 
									thisPos + pOffset, 
									Vec2f_zero, 
									_grapple_r.NextFloat() * 360.0f, 
									0.5f + (_grapple_r.NextFloat() * 0.5f), 
									XORRandom(3)+1, 
									0.0f, 
									false );
									
        if(p is null) continue; //bail if we stop getting particles
		
    	p.collides = false;
		p.Z = 200.0f;
		p.lighting = false;
    }
}