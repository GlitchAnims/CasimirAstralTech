// Fighter logic

#include "SpaceshipGlobal.as"
#include "ChargeCommon.as"
#include "MediumshipCommon.as"
#include "SpaceshipVars.as"
#include "ThrowCommon.as"
#include "KnockedCommon.as"
#include "Hitters.as"
#include "ShieldCommon.as"
#include "Help.as"
#include "CommonFX.as"

Random _wanderer_logic_r(16661);

void onInit( CBlob@ this )
{
	MediumshipInfo ship;
	ship.main_engine_force 			= WandererParams::main_engine_force;
	ship.secondary_engine_force 	= WandererParams::secondary_engine_force;
	ship.rcs_force 					= WandererParams::rcs_force;
	ship.ship_turn_speed 			= WandererParams::ship_turn_speed;
	ship.ship_drag 					= WandererParams::ship_drag;
	ship.max_speed 					= WandererParams::max_speed;
	
	ship.firing_rate 				= WandererParams::firing_rate;
	ship.firing_burst 				= WandererParams::firing_burst;
	ship.firing_delay 				= WandererParams::firing_delay;
	ship.firing_spread 				= WandererParams::firing_spread;
	ship.firing_cost 				= WandererParams::firing_cost;
	ship.shot_speed 				= WandererParams::shot_speed;
	ship.shot_lifetime 				= WandererParams::shot_lifetime;
	this.set("shipInfo", @ship);
	
	/*ManaInfo manaInfo;
	manaInfo.maxMana = FrigateParams::MAX_MANA;
	manaInfo.manaRegen = FrigateParams::MANA_REGEN;
	this.set("manaInfo", @manaInfo);*/

	this.set_u32( "m1_heldTime", 0 );
	this.set_u32( "m2_heldTime", 0 );

	this.set_u32( "m1_shotTime", 0 );

	this.set_bool( "leftCannonTurn", false);

	this.set_f32("broadside_chargeup", 0);
	this.set_bool("broadside_firing", false);

	this.set_bool("broadside_L1", false);
	this.set_bool("broadside_L2", false);
	this.set_bool("broadside_L3", false);

	//this.set_bool("broadside_R1", false);
	//this.set_bool("broadside_R2", false);
	//this.set_bool("broadside_R3", false);

	this.set_bool("shifted", false);
	
	this.Tag(mediumTag);
	
	this.push("names to activate", "keg");
	this.push("names to activate", "nuke");

	//centered on arrows
	//this.set_Vec2f("inventory offset", Vec2f(0.0f, 122.0f));
	//centered on items
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	this.getShape().SetGravityScale(0);
	
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right | CBlob::map_collide_nodeath);
	this.getCurrentScript().removeIfTag = "dead";
	

	if(isClient())
	{
		this.getSprite().SetEmitSound("engine_loop.ogg");
		this.getSprite().SetEmitSoundPaused(false);
		this.getSprite().SetEmitSoundVolume(0);
		this.getSprite().SetEmitSoundSpeed(0);
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
	u32 gameTime = getGameTime();
	
	if (isServer() && (gameTime + this.getNetworkID()) % 30 == 0) //once a second, server only
	{ 
		spawnAttachments(this);
	}

	// vvvvvvvvvvvvvv CLIENT-SIDE ONLY vvvvvvvvvvvvvvvvvvv
	//if (!isClient()) return;
	if (this.isInInventory()) return;
	if (!isClient()) return;
	
    MediumshipInfo@ ship;
	if (!this.get( "shipInfo", @ship )) 
	{ return; }
	
	CPlayer@ thisPlayer = this.getPlayer();
	if ( thisPlayer is null )
	{ return; }

	SpaceshipVars@ moveVars;
    if (!this.get( "moveVars", @moveVars )) {
        return;
    }

	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	f32 blobAngle = this.getAngleDegrees();
	blobAngle = Maths::Abs(blobAngle+270) % 360;
	int teamNum = this.getTeamNum();
	bool facingLeft = this.isFacingLeft();
	bool isMyPlayer = this.isMyPlayer();

	//gun logic
	s32 thisCharge = this.get_s32(absoluteCharge_string);

	s32 m1ChargeCost = ship.firing_cost;
	s32 m2ChargeCost = 50;

	bool pressed_m1 = this.isKeyPressed(key_action1);
	bool pressed_m2 = this.isKeyPressed(key_action2);
	
	u32 m1Time = this.get_u32( "m1_heldTime");
	u32 m2Time = this.get_u32( "m2_heldTime");

	u32 m1ShotTicks = this.get_u32( "m1_shotTime" );

	bool broadsideFiring = this.get_bool("broadside_firing"); //checks if firing procedure has been initiated
	bool canFireBroadside = m1ShotTicks >= ship.firing_rate;

	f32 broadsideLoad = 0.0f;
	if (broadsideFiring)
	{
		broadsideLoad = this.get_f32("broadside_chargeup");
	}
	else
	{
		u32 broadsideDelay = 30; //ticks before firing broadside
		float m1Mult = thisCharge >= m1ChargeCost ? 1.0f : 0.0f;
		float m1Chargeup = canFireBroadside ? m1Time : 0;
		broadsideLoad = Maths::Clamp((Maths::Max(m1Chargeup, 0) / float(broadsideDelay)) * m1Mult, 0.0f, 1.0f); //load percentage
	}

	Vec2f thisAimVec = this.getAimPos() - thisPos;
	float thisAimAngle = thisAimVec.AngleDegrees();

	float angleDiff = Maths::FMod(thisAimAngle + blobAngle, 360.0f);
	if (angleDiff > 180.0f) angleDiff = -360.0f + angleDiff;
	bool leftBroadside = angleDiff > 0.0f;

	float firingAngle = blobAngle + (leftBroadside ? -90 : 90);
	if (leftBroadside)
	{
		firingAngle -= Maths::Clamp(angleDiff, 45.0f, 135.0f) - 90;
	}
	else
	{
		firingAngle -= Maths::Clamp(angleDiff, -135.0f, -45.0f) + 90;
	}

	float maxSpread = float(ship.firing_spread);
	float shotSpread = maxSpread - (broadsideLoad * maxSpread); // angle in either direction

	Vec2f[] cannonPos =
	{
		Vec2f(13.0f, -13),
		Vec2f(12.0f, -1),
		Vec2f(13.0f, 11)
	};

	for(int i = 0; i < cannonPos.length(); i++)
	{
		if (leftBroadside) cannonPos[i].x *= -1.0f;
		cannonPos[i].RotateByDegrees(blobAngle+90);
		cannonPos[i] += thisPos;
	}
	
	if (pressed_m1 && !broadsideFiring && canFireBroadside)
	{
		for(int i = 0; i < cannonPos.length(); i++)
		{
			makeCannonChargeParticles(cannonPos[i], thisVel, broadsideLoad*0.2f, teamNum); //fancy particle effects
		}
		if (isMyPlayer)
		{
			SColor guideColor = broadsideLoad < 1.0f ? redConsoleColor : yellowConsoleColor;
			float guideLength = 256.0f;
			Vec2f guide1Pos = Vec2f(guideLength, 0);
			Vec2f guide2Pos = Vec2f(guideLength, 0);
			if (leftBroadside)
			{
				guide1Pos.RotateBy(firingAngle + shotSpread);
				guide2Pos.RotateBy(firingAngle - shotSpread);
			}
			else
			{
				guide1Pos.RotateBy(firingAngle - shotSpread);
				guide2Pos.RotateBy(firingAngle + shotSpread);
			}
			drawParticleLine(cannonPos[0], cannonPos[0] + guide1Pos, Vec2f_zero, guideColor, 0, 2.0f);
			drawParticleLine(cannonPos[2], cannonPos[2] + guide2Pos, Vec2f_zero, guideColor, 0, 2.0f);
		}
	}
	else if (!pressed_m1 && !broadsideFiring && broadsideLoad > 0) //initiate firing procedure
	{
		broadsideFiring = true;
		this.set_bool("broadside_L1", true);
		this.set_bool("broadside_L2", true);
		this.set_bool("broadside_L3", true);
	}

	if (broadsideFiring)	//firing procedure
	{
		bool firedThisTick = false;

		bool L1charged = this.get_bool("broadside_L1");
		bool L2charged = this.get_bool("broadside_L2");
		bool L3charged = this.get_bool("broadside_L3");

		float shotSpeed = ship.shot_speed;
		float shotLifetime = ship.shot_lifetime;

		float fireChance = 0.1f + (0.7f * broadsideLoad); // chance for any given cannon to fire each tick

		//individual cannon fire
		if (L1charged)
		{
			if (_wanderer_logic_r.NextFloat() <= fireChance && !firedThisTick) //roll chance if cannon is charged
			{
				if (isMyPlayer) fireBroadsideShot(this, cannonPos[0], thisVel, firingAngle, this.getNetworkID(), 4, shotLifetime, m1ChargeCost, shotSpeed, shotSpread);
				firedThisTick = true;
				L1charged = false;
				this.set_bool("broadside_L1", false);
			}
			else
			{
				makeCannonChargeParticles(cannonPos[0], thisVel, broadsideLoad*0.2f, teamNum); //fancy particle effects
			}
		}
		if (L2charged)
		{
			if (_wanderer_logic_r.NextFloat() <= fireChance && !firedThisTick) //roll chance if cannon is charged
			{
				if (isMyPlayer) fireBroadsideShot(this, cannonPos[1], thisVel, firingAngle, this.getNetworkID(), 4, shotLifetime, m1ChargeCost, shotSpeed, shotSpread);
				firedThisTick = true;
				L2charged = false;
				this.set_bool("broadside_L2", false);
			}
			else
			{
				makeCannonChargeParticles(cannonPos[1], thisVel, broadsideLoad*0.2f, teamNum); //fancy particle effects
			}
		}
		if (L3charged)
		{
			if (_wanderer_logic_r.NextFloat() <= fireChance && !firedThisTick) //roll chance if cannon is charged
			{
				if (isMyPlayer) fireBroadsideShot(this, cannonPos[2], thisVel, firingAngle, this.getNetworkID(), 4, shotLifetime, m1ChargeCost, shotSpeed, shotSpread);
				firedThisTick = true;
				L3charged = false;
				this.set_bool("broadside_L3", false);
			}
			else
			{
				makeCannonChargeParticles(cannonPos[2], thisVel, broadsideLoad*0.2f, teamNum); //fancy particle effects
			}
		}

		bool stillCharged = L1charged || L2charged || L3charged;
		if (!stillCharged) //if no more cannons left to fire, shutdown procedure
		{
			broadsideLoad = 0.0f;
			broadsideFiring = false;
		}

		m1ShotTicks = 0;
	}

	if (pressed_m1 && canFireBroadside)
	{ m1Time++; }
	else { m1Time = 0; }
	this.set_u32( "m1_heldTime", m1Time );

	if (pressed_m2)
	{ m2Time++; }
	else { m2Time = 0; }
	this.set_u32( "m2_heldTime", m2Time );

	if (m1ShotTicks < 500)
	{ m1ShotTicks++; }
	this.set_u32( "m1_shotTime", m1ShotTicks );

	this.set_bool("broadside_firing", broadsideFiring);
	this.set_f32("broadside_chargeup", broadsideLoad);

	//sound logic
	/*
	if(broadsideLoad > 1.0f)
	{
		this.getSprite().SetEmitSoundVolume(0.0f);
	}
	else
	{
		this.getSprite().SetEmitSoundVolume(2.0f * broadsideLoad);
		this.getSprite().SetEmitSoundSpeed(2.0f * broadsideLoad);
	}*/
}

void fireBroadsideShot(CBlob@ this, Vec2f barrelPos = Vec2f_zero, Vec2f shipVel = Vec2f_zero, float barrelAngle = 0, u16 thisNetID = 0, u8 shotType = 0, float shotLifetime = 0, s32 chargeDrain = 0, float shotSpeed = 0, float shotSpread = 0)
{
	CBitStream params;
	params.write_u16(thisNetID); //ownerID
	params.write_u8(shotType); //shot type, see SpaceshipGlobal.as
	params.write_f32(shotLifetime); //shot lifetime
	params.write_s32(chargeDrain); //charge drain

	Vec2f fireVec = Vec2f(1.0f,0) * shotSpeed; 
	f32 randomSpread = shotSpread * (1.0f - (2.0f * _wanderer_logic_r.NextFloat()) ); //shot spread
	fireVec.RotateByDegrees(barrelAngle + randomSpread); //shot vector
	fireVec += shipVel; //adds ship speed

	params.write_Vec2f(barrelPos); //shot position
	params.write_Vec2f(fireVec); //shot velocity
	
	this.SendCommandOnlyServer(this.getCommandID(shot_command_ID), params);
}

void makeCannonChargeParticles( Vec2f barrelPos = Vec2f_zero, Vec2f blobVel = Vec2f_zero, f32 mult = 0.0f, int teamNum = 0)
{
	if (barrelPos == Vec2f_zero) //abort if no barrel pos
	{ return; }

	s32 particleNum = 2.0f + (30.0f * mult);

	//SColor color = getTeamColorWW(teamNum);
	SColor color = SColor(255, 10, 255, 10); //green particles

	for(int i = 0; i < particleNum; i++)
	{
		Vec2f pNorm = Vec2f(1,0);
		pNorm.RotateByDegrees(360.0f * _wanderer_logic_r.NextFloat());

		Vec2f pVel = (pNorm * mult) * 5.0f;
		pVel += blobVel;
		Vec2f pGrav = (-pNorm * mult) * 0.5;

		CParticle@ p = ParticlePixelUnlimited(barrelPos, pVel, color, true);
        if(p !is null)
        {
   	        p.collides = false;
   	        p.gravity = pGrav;
            p.bounce = 0;
            p.Z = 20 * (1.0f - (2.0f * _wanderer_logic_r.NextFloat()));
            p.timeout = 3.0f + (15.0f * mult);
			//p.timeout = 30;
    	}
	}
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    if (customData == Hitters::suicide)
	{
		return 0;
	}
	else if (customData == Hitters::arrow)
	{
		damage *= 0.25;
	}

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
	//empty
}

void spawnAttachments(CBlob@ ownerBlob)
{
	if (ownerBlob == null)
	{ return; }

	CAttachment@ attachments = ownerBlob.getAttachments();
	if (attachments == null)
	{ return; }

	Vec2f ownerPos = ownerBlob.getPosition();
	int teamNum = ownerBlob.getTeamNum();

	AttachmentPoint@ shieldSlot = attachments.getAttachmentPointByName("SHIELDSLOT");

	if (shieldSlot != null)
	{
		Vec2f slotOffset = shieldSlot.offset;
		CBlob@ turret = shieldSlot.getOccupied();
		if (turret == null)
		{
			CBlob@ blob = server_CreateBlob( "shield_full" , teamNum, ownerPos + slotOffset);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				ownerBlob.server_AttachTo(blob, shieldSlot);
				blob.set_u32("ownerBlobID", ownerBlob.getNetworkID());
			}
		}
	}
	
}