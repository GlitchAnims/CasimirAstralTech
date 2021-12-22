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

Random _martyr_logic_r(16661);

void onInit( CBlob@ this )
{
	this.set_s32(absoluteCharge_string, 0);
	this.set_s32(absoluteMaxCharge_string, 0);
	if (isServer())
	{
		ChargeInfo chargeInfo;
		chargeInfo.charge 			= MartyrParams::CHARGE_START * MartyrParams::CHARGE_MAX;
		chargeInfo.chargeMax 		= MartyrParams::CHARGE_MAX;
		chargeInfo.chargeRegen 		= MartyrParams::CHARGE_REGEN;
		chargeInfo.chargeRate 		= MartyrParams::CHARGE_RATE;
		this.set("chargeInfo", @chargeInfo);
	}
	
	MediumshipInfo ship;
	ship.main_engine_force 			= MartyrParams::main_engine_force;
	ship.secondary_engine_force 	= MartyrParams::secondary_engine_force;
	ship.rcs_force 					= MartyrParams::rcs_force;
	ship.ship_turn_speed 			= MartyrParams::ship_turn_speed;
	ship.ship_drag 					= MartyrParams::ship_drag;
	ship.max_speed 					= MartyrParams::max_speed;
	
	ship.firing_rate 				= MartyrParams::firing_rate;
	ship.firing_burst 				= MartyrParams::firing_burst;
	ship.firing_delay 				= MartyrParams::firing_delay;
	ship.firing_spread 				= MartyrParams::firing_spread;
	ship.firing_cost 				= MartyrParams::firing_cost;
	ship.shot_speed 				= MartyrParams::shot_speed;
	ship.shot_lifetime 				= MartyrParams::shot_lifetime;
	this.set("shipInfo", @ship);
	
	/*ManaInfo manaInfo;
	manaInfo.maxMana = FrigateParams::MAX_MANA;
	manaInfo.manaRegen = FrigateParams::MANA_REGEN;
	this.set("manaInfo", @manaInfo);*/

	this.set_u32( "m1_heldTime", 0 );
	this.set_u32( "m2_heldTime", 0 );

	this.set_u32( "m1_shotTime", 0 );

	this.set_bool( "leftCannonTurn", false);

	this.set_bool("shifted", false);
	
	this.Tag("player");
	this.Tag("hull");
	this.Tag(mediumTag);
	
	this.push("names to activate", "keg");
	this.push("names to activate", "nuke");

	//centered on arrows
	//this.set_Vec2f("inventory offset", Vec2f(0.0f, 122.0f));
	//centered on items
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	this.getShape().SetGravityScale(0);

	this.getShape().getConsts().net_threshold_multiplier = 0.5f;
	
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
	f32 blobAngle = this.getAngleDegrees() + 270;
	blobAngle = Maths::Abs(blobAngle) % 360;
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

	if (pressed_m1 && m1Time >= ship.firing_delay && isMyPlayer && thisCharge >= m1ChargeCost)
	{
		if (m1ShotTicks >= ship.firing_rate * moveVars.firingRateFactor)
		{
			bool leftCannon = this.get_bool( "leftCannonTurn" ); //this is used if the "gun" has 2 firing positions
			this.set_bool( "leftCannonTurn", !leftCannon);

			CBitStream params;
			params.write_u16(this.getNetworkID()); //ownerID
			params.write_u8(2); //shot type
			params.write_f32(ship.shot_lifetime); //shot lifetime
			params.write_s32(m1ChargeCost); //charge drain

			uint bulletCount = ship.firing_burst;
			for (uint i = 0; i < bulletCount; i ++)
			{
				f32 cannonMult = leftCannon ? 1.0f : -1.0f;
				Vec2f firePos = Vec2f(9.0f, 9.5 * cannonMult); //barrel pos
				firePos.RotateByDegrees(blobAngle);
				firePos += thisPos; //fire pos

				Vec2f fireVec = Vec2f(1.0f,0) * ship.shot_speed; 
				f32 randomSpread = ship.firing_spread * (1.0f - (2.0f * _martyr_logic_r.NextFloat()) ); //shot spread
				fireVec.RotateByDegrees(blobAngle + randomSpread); //shot vector
				fireVec += thisVel; //adds ship speed

				params.write_Vec2f(firePos); //shot position
				params.write_Vec2f(fireVec); //shot velocity
			}
			this.SendCommandOnlyServer(this.getCommandID(shot_command_ID), params);

			m1ShotTicks = 0;
		}
	}
	
	s32 mainCannonDelay = 60; //ticks before firing main cannon
	f32 m2Mult = thisCharge >= m2ChargeCost ? 1.0f : 0.0f;
	f32 cannonLoad = (float(m2Time) / float(mainCannonDelay)) * m2Mult; //load percentage
	if (pressed_m2 && cannonLoad <= 1.0f)
	{
		Vec2f firePos = Vec2f(11.0f, 0); //barrel pos
		firePos.RotateByDegrees(blobAngle);
		firePos += thisPos; //fire pos

		makeCannonChargeParticles(firePos, thisVel, cannonLoad, teamNum); //fancy particle effects

		if (cannonLoad >= 1.0f && isMyPlayer) //fires after 2 seconds
		{
			CBitStream params;
			params.write_u16(this.getNetworkID()); //ownerID
			params.write_u8(5); //shot type, see SpaceshipGlobal.as
			params.write_f32(1.2f); //shot lifetime
			params.write_s32(m2ChargeCost); //charge drain

			uint bulletCount = ship.firing_burst;
			for (uint i = 0; i < bulletCount; i ++)
			{
				Vec2f fireVec = Vec2f(1.0f,0) * ship.shot_speed; 
				f32 randomSpread = ship.firing_spread * (1.0f - (2.0f * _martyr_logic_r.NextFloat()) ); //shot spread
				fireVec.RotateByDegrees(blobAngle + randomSpread); //shot vector
				fireVec += thisVel; //adds ship speed

				params.write_Vec2f(firePos); //shot position
				params.write_Vec2f(fireVec); //shot velocity
			}
			this.SendCommandOnlyServer(this.getCommandID(shot_command_ID), params);
		}
	}

	if (pressed_m1)
	{ m1Time++; }
	else { m1Time = 0; }
	
	if (pressed_m2)
	{ m2Time++; }
	else { m2Time = 0; }
	this.set_u32( "m1_heldTime", m1Time );
	this.set_u32( "m2_heldTime", m2Time );

	m1ShotTicks++;
	this.set_u32( "m1_shotTime", m1ShotTicks );

	//sound logic
	/*Vec2f vel = this.getVelocity();
	float posVelX = Maths::Abs(vel.x);
	float posVelY = Maths::Abs(vel.y);
	if(posVelX > 3.0f)
	{
		this.getSprite().SetEmitSoundVolume(3.0f);
	}
	else
	{
		this.getSprite().SetEmitSoundVolume(1.0f * (posVelX > posVelY ? posVelX : posVelY));
	}*/

	if(cannonLoad > 1.0f)
	{
		this.getSprite().SetEmitSoundVolume(0.0f);
	}
	else
	{
		this.getSprite().SetEmitSoundVolume(2.0f * cannonLoad);
		this.getSprite().SetEmitSoundSpeed(2.0f * cannonLoad);
	}
}

void makeCannonChargeParticles(Vec2f barrelPos = Vec2f_zero, Vec2f blobVel = Vec2f_zero, f32 mult = 0.0f, int teamNum = 0)
{
	if (barrelPos == Vec2f_zero) //abort if no barrel pos
	{ return; }

	s32 particleNum = 2.0f + (30.0f * mult);

	//SColor color = getTeamColorWW(teamNum);
	SColor color = SColor(255, 10, 255, 10); //green particles

	for(int i = 0; i < particleNum; i++)
	{
		Vec2f pNorm = Vec2f(1,0);
		pNorm.RotateByDegrees(360.0f * _martyr_logic_r.NextFloat());

		Vec2f pVel = (pNorm * mult) * 5.0f;
		pVel += blobVel;
		Vec2f pGrav = (-pNorm * mult) * 0.5;

		CParticle@ p = ParticlePixelUnlimited(barrelPos, pVel, color, true);
        if(p !is null)
        {
   	        p.collides = false;
   	        p.gravity = pGrav;
            p.bounce = 0;
            p.Z = 20 * (1.0f - (2.0f * _martyr_logic_r.NextFloat()));
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

void blast( Vec2f pos , int particleNum)
{
	if(!isClient())
	{return;}

	Sound::Play("GenericExplosion1.ogg", pos, 0.8f, 0.8f + XORRandom(10)/10.0f);

	for (int i = 0; i < particleNum; i++)
    {
        Vec2f vel(_martyr_logic_r.NextFloat() * 3.0f, 0);
        vel.RotateBy(_martyr_logic_r.NextFloat() * 360.0f);

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

void spawnAttachments(CBlob@ ownerBlob)
{
	if (ownerBlob == null)
	{ return; }

	CAttachment@ attachments = ownerBlob.getAttachments();
	if (attachments == null)
	{ return; }

	Vec2f ownerPos = ownerBlob.getPosition();
	string turretName = "turret_flak";
	int teamNum = ownerBlob.getTeamNum();

	AttachmentPoint@ slot1 = attachments.getAttachmentPointByName("TURRETSLOT1");
	AttachmentPoint@ slot2 = attachments.getAttachmentPointByName("TURRETSLOT2");
	AttachmentPoint@ shieldSlot = attachments.getAttachmentPointByName("SHIELDSLOT");

	if (slot1 != null)
	{
		Vec2f slotOffset = slot1.offset;
		CBlob@ turret = slot1.getOccupied();
		if (turret == null)
		{
			CBlob@ blob = server_CreateBlob( turretName , teamNum, ownerPos + slotOffset);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				ownerBlob.server_AttachTo(blob, slot1);
				blob.set_u32("ownerBlobID", ownerBlob.getNetworkID());
			}
		}
	}
	if (slot2 != null)
	{
		Vec2f slotOffset = slot2.offset;
		CBlob@ turret = slot2.getOccupied();
		if (turret == null)
		{
			CBlob@ blob = server_CreateBlob( turretName , teamNum, ownerPos + slotOffset);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				ownerBlob.server_AttachTo(blob, slot2);
				blob.set_u32("ownerBlobID", ownerBlob.getNetworkID());
			}
		}
	}
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