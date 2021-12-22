// Fighter logic

#include "SpaceshipGlobal.as"
#include "ChargeCommon.as"
#include "TurretCommon.as"
#include "SpaceshipVars.as"
#include "CommonFX.as"

Random _flak_turret_logic_r(98444);
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
	this.set("shipInfo", @turret);
	
	/*ManaInfo manaInfo;
	manaInfo.maxMana = FrigateParams::MAX_MANA;
	manaInfo.manaRegen = FrigateParams::MANA_REGEN;
	this.set("manaInfo", @manaInfo);*/

	this.set_u32("ownerBlobID", 0);

	this.set_u32( "space_heldTime", 0 );
	this.set_u32( "space_shotTime", 0 );
	
	this.Tag("npc");
	//this.Tag("hull");
	this.Tag("ignore crouch");

	//centered on arrows
	//this.set_Vec2f("inventory offset", Vec2f(0.0f, 122.0f));
	//centered on items
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	
	this.getShape().SetRotationsAllowed(false); //no spinning
	this.getShape().SetGravityScale(0);
	this.getShape().getConsts().mapCollisions = false;

	this.getShape().getConsts().net_threshold_multiplier = 0.5f;
	
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right | CBlob::map_collide_nodeath);
	this.getCurrentScript().removeIfTag = "dead";
	

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
	// vvvvvvvvvvvvvv SERVER-SIDE ONLY vvvvvvvvvvvvvvvvvvv
	if (!isServer()) return;
	if (this.isInInventory()) return;

	bool attached = this.isAttached();
	u32 ownerBlobID = this.get_u32("ownerBlobID");
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
	Vec2f thisVel = this.getVelocity();
	f32 blobAngle = this.getAngleDegrees();
	blobAngle = (blobAngle+360.0f) % 360;

	Vec2f ownerAimpos = ownerBlob.getAimPos();
	Vec2f aimVec = ownerAimpos - thisPos;
	f32 aimAngle = aimVec.getAngleDegrees();
	aimAngle *= -1.0f;

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

	bool pressed_space = ownerBlob.isKeyPressed(key_action3);
	u32 spaceTime = this.get_u32( "space_heldTime");

	u32 spaceShotTicks = this.get_u32( "space_shotTime" );
	u32 spaceFiringDelay = turret.firing_delay;

	if (pressed_space && spaceTime >= spaceFiringDelay && ownerCharge >= spaceChargeCost)
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
				f32 randomSpread = turret.firing_spread * (1.0f - (2.0f * _flak_turret_logic_r.NextFloat()) ); //shot spread
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
	Vec2f thisPos = this.getPosition();
	blast( thisPos , 12);
}

void blast( Vec2f pos , int amount)
{
	if(!isClient())
	{return;}

	Sound::Play("GenericExplosion1.ogg", pos, 0.8f, 0.8f + XORRandom(10)/10.0f);

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_flak_turret_logic_r.NextFloat() * 3.0f, 0);
        vel.RotateBy(_flak_turret_logic_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated("GenericBlast6.png", 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.5f, 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if(p is null) continue; //bail if we stop getting particles
		
    	p.fastcollision = true;
        p.damping = 0.85f;
		p.Z = 200.0f;
		p.lighting = false;
    }
}