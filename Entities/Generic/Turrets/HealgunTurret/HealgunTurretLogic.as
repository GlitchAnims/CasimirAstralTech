// Artillery Turret logic

#include "SpaceshipGlobal.as"
#include "ChargeCommon.as"
#include "TurretCommon.as"
#include "SpaceshipVars.as"
#include "CommonFX.as"

void onInit( CBlob@ this )
{
	TurretInfo turret;
	turret.turret_turn_speed 		= HealgunParams::turret_turn_speed;
	turret.turret_targeting_range 	= HealgunParams::turret_targeting_range;
	
	turret.firing_rate 				= HealgunParams::firing_rate;
	turret.firing_burst 			= HealgunParams::firing_burst;
	turret.firing_delay 			= HealgunParams::firing_delay;
	turret.firing_spread 			= HealgunParams::firing_spread;
	turret.firing_cost 				= HealgunParams::firing_cost;
	turret.shot_speed 				= HealgunParams::shot_speed;
	turret.auto_target_ID			= 0;
	this.set("shipInfo", @turret);

	turretSetup(this);
}

void onSetPlayer( CBlob@ this, CPlayer@ player )
{
	if (player !is null){
		player.SetScoreboardVars("ScoreboardIcons.png", 2, Vec2f(16,16));
	}
}

void onTick( CBlob@ this )
{
	// vvvvvvvvvvvvvv SERVER-SIDE ONLY vvvvvvvvvvvvvvvvvvv
	if (!isServer()) return;
	if (this.isInInventory()) return;

	bool isAuto = this.get_bool("automatic");
	u32 gameTime = getGameTime();

	bool attached = this.isAttached();
	u16 ownerBlobID = this.get_u16("ownerBlobID");
	CBlob@ ownerBlob = getBlobByNetworkID(ownerBlobID);
	if (!attached || ownerBlobID == 0 || ownerBlob == null)
	{ 
		this.server_Die();
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
	f32 blobAngle = this.getAngleDegrees();
	blobAngle = (blobAngle+360.0f) % 360;

	Vec2f ownerAimpos = ownerBlob.getAimPos();
	Vec2f aimVec = ownerAimpos - thisPos;
	f32 aimAngle = aimVec.getAngleDegrees();
	aimAngle *= -1.0f;

	bool forceActivateFire = false;

	float targetingRange = turret.turret_targeting_range;

	if (isAuto)
	{
		int teamNum = this.getTeamNum();
		f32 shotSpeed = turret.shot_speed;
		
		if ((gameTime + this.getNetworkID()) % 60 == 0 && turret.auto_target_ID == 0) //once every 2 seconds
		{
			//turret.auto_target_ID = 0;

			CMap@ map = getMap(); //standard map check
			if (map is null)
			{ return; }

			CBlob@[] blobsInRadius;
			map.getBlobsInRadius(thisPos, targetingRange, @blobsInRadius); //get a target
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob@ b = blobsInRadius[i];
				if (b is null || b is ownerBlob)
				{ continue; }

				if (b.getTeamNum() != teamNum)
				{ continue; }

				float bSpeed = b.getVelocity().getLength();
				Vec2f bPos = b.getPosition();
				Vec2f bVec = bPos - thisPos;
				float bDist = bVec.getLength();
				
				if (!b.hasTag("hull") || bSpeed > 1.5f || bDist < 8.0f || b.getHealth() >= b.getInitialHealth())
				{ continue; }

				if (map.rayCastSolidNoBlobs(thisPos, bPos))
				{ continue; }
				
				turret.auto_target_ID = b.getNetworkID();
				break;
			}
		}

		CBlob@ b = getBlobByNetworkID(turret.auto_target_ID);
		if (b != null)
		{
			Vec2f bPos = b.getPosition();
			Vec2f bVel = b.getVelocity();

			Vec2f targetVec = bPos - thisPos;
			f32 targetDist = targetVec.getLength();
			if (targetDist > targetingRange || bVel.getLength() > 1.5f || b.getHealth() >= b.getInitialHealth()) //too far away, lose target
			{
				turret.auto_target_ID = 0;
			}
			else
			{
				aimVec = targetVec;
				aimAngle = targetVec.getAngleDegrees() * -1.0f;

				f32 angleDiff = aimAngle - blobAngle;
				angleDiff += angleDiff > 180 ? -360 : angleDiff < -180 ? 360 : 0;

				forceActivateFire = Maths::Abs(angleDiff) < 5;
			}
		}
		else // if null, means it died. Reset.
		{
			turret.auto_target_ID = 0;
		}
	}

	if (blobAngle != aimAngle) //aiming logic
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

	if (pressed_space && spaceTime >= spaceFiringDelay && ownerCharge >= spaceChargeCost)
	{
		if (spaceShotTicks >= turret.firing_rate * moveVars.firingRateFactor)
		{
			removeCharge(ownerBlob, spaceChargeCost, true);

			u8 shotType = 10; //shot type
			f32 lifeTime = targetingRange; //shot lifetime
			
			uint bulletCount = turret.firing_burst;
			for (uint i = 0; i < bulletCount; i ++)
			{
				Vec2f firePos = Vec2f(10.0f, 0.0f); //barrel pos
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
		if (spaceTime < spaceFiringDelay)
		{ spaceTime++; }
	}
	else 
	{
		if (spaceTime > 0)
		{ spaceTime--; }
	}
	this.set_u32( "space_heldTime", spaceTime );
	

	if (spaceShotTicks < 500)
	{
		spaceShotTicks++;
		this.set_u32( "space_shotTime", spaceShotTicks );
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