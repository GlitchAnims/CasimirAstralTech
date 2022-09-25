// Fighter logic

#include "SpaceshipGlobal.as"
#include "ChargeCommon.as"
#include "TurretCommon.as"
#include "SpaceshipVars.as"
#include "CommonFX.as"

void onInit( CBlob@ this )
{
	TurretInfo turret;
	turret.turret_turn_speed 	= GatlingParams::turret_turn_speed;
	
	turret.firing_rate 			= GatlingParams::firing_rate;
	turret.firing_burst 		= GatlingParams::firing_burst;
	turret.firing_delay 		= GatlingParams::firing_delay;
	turret.firing_spread 		= GatlingParams::firing_spread;
	turret.firing_cost 			= GatlingParams::firing_cost;
	turret.shot_speed 			= GatlingParams::shot_speed;
	turret.auto_target_ID		= 0;
	this.set("shipInfo", @turret);
	
	turretSetup(this);
	
	if(isClient())
	{
		CSprite@ thisSprite = this.getSprite();
		thisSprite.SetEmitSound("gatling_windup.ogg");
		thisSprite.SetEmitSoundPaused(false);
		thisSprite.SetEmitSoundVolume(0);
		thisSprite.SetEmitSoundSpeed(0);
	}
}

void onSetPlayer( CBlob@ this, CPlayer@ player )
{
	if (player !is null){
		player.SetScoreboardVars("ScoreboardIcons.png", 2, Vec2f(16,16));
	}
}

void onTick( CBlob@ this )
{
	if (this.isInInventory()) return;
	
	const bool is_server = isServer();
	
	bool isAuto = this.get_bool("automatic");
	u32 gameTime = getGameTime();

	bool attached = this.isAttached();
	u16 ownerBlobID = this.get_u16("ownerBlobID");
	CBlob@ ownerBlob = getBlobByNetworkID(ownerBlobID);
	if (!attached || ownerBlobID == 0 || ownerBlob == null)
	{ 
		if (is_server) this.server_Die();
		return;
	}

	TurretInfo@ turret;
	if (!this.get( "shipInfo", @turret )) 
	{ return; }

	SpaceshipVars@ moveVars;
	if (!ownerBlob.get( "moveVars", @moveVars )) {
		return;
	}

	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	f32 blobAngle = this.getAngleDegrees();
	blobAngle = (blobAngle+360.0f) % 360;

	Vec2f ownerAimpos = ownerBlob.getAimPos();
	Vec2f aimVec = ownerAimpos - thisPos;
	f32 aimAngle = aimVec.getAngleDegrees();
	aimAngle *= -1.0f;

	bool forceActivateFire = false;

	if (is_server && isAuto)
	{
		int teamNum = this.getTeamNum();
		f32 shotSpeed = turret.shot_speed;
		
		if ((gameTime + this.getNetworkID()) % 60 == 0) //once every 2 seconds
		{
			turret.auto_target_ID = 0;

			CMap@ map = getMap(); //standard map check
			if (map is null)
			{ return; }

			CBlob@[] blobsInRadius;
			map.getBlobsInRadius(thisPos, 512.0f, @blobsInRadius); //get a target
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob@ b = blobsInRadius[i];
				if (b is null)
				{ continue; }

				if (b.getTeamNum() == teamNum)
				{ continue; }

				if (!b.hasTag(mediumTag))
				{ continue; }
				
				turret.auto_target_ID = b.getNetworkID();
				break;
			}
		}

		CBlob@ b = getBlobByNetworkID(turret.auto_target_ID);
		if (b != null)
		{
			Vec2f bPos = b.getPosition();
			Vec2f bVel = b.getVelocity() - thisVel;
			//bPos += bVel * playerPing;

			Vec2f targetVec = bPos - thisPos;
			f32 targetDist = targetVec.getLength();
			if (targetDist > 512) //too far away, lose target
			{
				turret.auto_target_ID = 0;
			}
			else
			{
				f32 travelTicks = targetDist / shotSpeed;
				Vec2f futureTargetPos = bPos + (bVel*travelTicks);
				
				targetVec = futureTargetPos - thisPos;
				targetDist = targetVec.getLength();
				travelTicks = targetDist / shotSpeed;
				futureTargetPos = bPos + (bVel*travelTicks);

				aimVec = futureTargetPos - thisPos;
				aimAngle = aimVec.getAngleDegrees() * -1.0f;

				f32 angleDiff = aimAngle - blobAngle;
				angleDiff += angleDiff > 180 ? -360 : angleDiff < -180 ? 360 : 0;

				forceActivateFire = Maths::Abs(angleDiff) < 30;
			}
		}
	}

	if (is_server && blobAngle != aimAngle) //aiming logic
	{
		f32 turnSpeed = turret.turret_turn_speed; //turn rate

		f32 angleDiff = blobAngle - aimAngle;
		angleDiff = (angleDiff + 180) % 360 - 180;

		if (turnSpeed <= 0 || (angleDiff < turnSpeed && angleDiff > -turnSpeed)) //if turn difference is smaller than turn speed, snap to it
		{
			this.setAngleDegrees(aimAngle);
		}
		else
		{
			f32 turnAngle = angleDiff > 0 ? -turnSpeed : turnSpeed; //either left or right turn
			this.setAngleDegrees(blobAngle + turnAngle);
			this.setAngleDegrees(blobAngle + turnAngle);
		}
		blobAngle = this.getAngleDegrees();
	}
	
	//gun logic
	s32 ownerCharge = ownerBlob.get_s32(absoluteCharge_string);
	s32 spaceChargeCost = turret.firing_cost;

	bool pressed_space = ownerBlob.isKeyPressed(key_action3) || forceActivateFire;
	u32 spaceTime = this.get_u32( "space_heldTime");

	u32 spaceShotTicks = this.get_u32( "space_shotTime" );
	u32 spaceFiringDelay = turret.firing_delay;

	if (is_server && pressed_space && spaceTime >= spaceFiringDelay && ownerCharge >= spaceChargeCost)
	{
		if (spaceShotTicks >= turret.firing_rate * moveVars.firingRateFactor)
		{
			removeCharge(ownerBlob, spaceChargeCost, true);

			u8 shotType = 1; //shot type
			f32 lifeTime = 0.8; //shot lifetime
			
			uint bulletCount = turret.firing_burst;
			for (uint i = 0; i < bulletCount; i ++)
			{
				Vec2f firePos = Vec2f(8.0f, 0.0f); //barrel pos
				firePos.RotateByDegrees(blobAngle);
				firePos += thisPos; //fire pos

				Vec2f fireVec = Vec2f(1.0f,0) * turret.shot_speed; 
				f32 randomSpread = turret.firing_spread * (1.0f - (2.0f * _turret_logic_r.NextFloat()) ); //shot spread
				fireVec.RotateByDegrees(blobAngle + randomSpread); //shot vector
				fireVec += ownerBlob.getVelocity(); //adds owner ship speed

				turretFire(this, shotType, firePos, fireVec, lifeTime); //at TurretCommon.as
			}

			spaceShotTicks = 0;
		}
	}

	if (pressed_space) //this one's special because of gatling windup
	{
		if (spaceTime < spaceFiringDelay) spaceTime++;
	}
	else 
	{
		if (spaceTime > 0) spaceTime--;
	}
	this.set_u32( "space_heldTime", spaceTime );
	
	if (spaceShotTicks < 500)
	{
		spaceShotTicks++;
		this.set_u32( "space_shotTime", spaceShotTicks );
	}

	if (isClient())
	{
		//sound logic
		f32 windupPercentage = float(spaceTime) / spaceFiringDelay;
		//sound logic
		CSprite@ thisSprite = this.getSprite();
		if(windupPercentage <= 0.0f)
		{
			if (!thisSprite.getEmitSoundPaused())
			{
				thisSprite.SetEmitSoundPaused(true);
			}
			thisSprite.SetEmitSoundVolume(0.0f);
			thisSprite.SetEmitSoundSpeed(0.0f);
		}
		else
		{
			if (thisSprite.getEmitSoundPaused())
			{
				thisSprite.SetEmitSoundPaused(false);
			}
			thisSprite.SetEmitSoundVolume(windupPercentage);
			thisSprite.SetEmitSoundSpeed(windupPercentage);
		}
	}
}



f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    if (( hitterBlob.getName() == "wraith" || hitterBlob.getName() == "orb" ) && hitterBlob.getTeamNum() == this.getTeamNum())
        return 0;

	if (isClient())
	{
		makeHullHitSparks( worldPoint, 15 );
	}

    return damage;
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
	//empty
}

void onDie( CBlob@ this )
{
	turretDeath(this);
}