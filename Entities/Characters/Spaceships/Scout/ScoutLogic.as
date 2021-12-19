// Fighter logic

#include "SpaceshipGlobal.as"
#include "ChargeCommon.as"
#include "SmallshipCommon.as"
#include "SpaceshipVars.as"
#include "ThrowCommon.as"
#include "KnockedCommon.as"
#include "Hitters.as"
#include "ShieldCommon.as"
#include "Help.as"
#include "CommonFX.as"

Random _scout_logic_r(23388);
void onInit( CBlob@ this )
{
	this.set_s32(absoluteCharge_string, 0);
	this.set_s32(absoluteMaxCharge_string, 0);
	if (isServer())
	{
		ChargeInfo chargeInfo;
		chargeInfo.charge 			= ScoutParams::CHARGE_START * ScoutParams::CHARGE_MAX;
		chargeInfo.chargeMax 		= ScoutParams::CHARGE_MAX;
		chargeInfo.chargeRegen 		= ScoutParams::CHARGE_REGEN;
		chargeInfo.chargeRate 		= ScoutParams::CHARGE_RATE;
		this.set("chargeInfo", @chargeInfo);
	}
	
	SmallshipInfo ship;
	ship.main_engine_force 			= ScoutParams::main_engine_force;
	ship.secondary_engine_force 	= ScoutParams::secondary_engine_force;
	ship.rcs_force 					= ScoutParams::rcs_force;
	ship.ship_turn_speed 			= ScoutParams::ship_turn_speed;
	ship.ship_drag 					= ScoutParams::ship_drag;
	ship.max_speed 					= ScoutParams::max_speed;
	
	ship.firing_rate 				= ScoutParams::firing_rate;
	ship.firing_burst 				= ScoutParams::firing_burst;
	ship.firing_delay 				= ScoutParams::firing_delay;
	ship.firing_spread 				= ScoutParams::firing_spread;
	ship.shot_speed 				= ScoutParams::shot_speed;
	this.set("shipInfo", @ship);
	
	//keys setup

	this.set_u32( "m1_heldTime", 0 );
	this.set_u32( "m2_heldTime", 0 );

	this.set_u32( "m1_shotTime", 0 );
	this.set_u32( "m2_shotTime", 0 );

	this.set_bool("shifted", false);
	
	this.Tag("player");
	this.Tag("hull");
	this.Tag("ignore crouch");
	
	this.push("names to activate", "keg");
	this.push("names to activate", "nuke");

	//centered on arrows
	//this.set_Vec2f("inventory offset", Vec2f(0.0f, 122.0f));
	//centered on items
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	//no spinning
	this.getShape().SetRotationsAllowed(false);
	//this.getShape().SetGravityScale(0);

	this.getShape().getConsts().net_threshold_multiplier = 0.5f;
	
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right | CBlob::map_collide_nodeath);
	this.getCurrentScript().removeIfTag = "dead";
	

	/*if(isClient())
	{
		this.getSprite().SetEmitSound("engine_loop.ogg");
		this.getSprite().SetEmitSoundPaused(true);
	}*/
}

void onSetPlayer( CBlob@ this, CPlayer@ player )
{
	if (player !is null){
		player.SetScoreboardVars("ScoreboardIcons.png", 2, Vec2f(16,16));
	}
}

void onTick( CBlob@ this )
{
	// vvvvvvvvvvvvvv CLIENT-SIDE ONLY vvvvvvvvvvvvvvvvvvv
	//if (!isClient()) return;
	if (this.isInInventory()) return;
	if (!this.isMyPlayer()) return;

    SmallshipInfo@ ship;
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
	blobAngle = (blobAngle+360.0f) % 360;

	//gun logic
	bool pressed_m1 = this.isKeyPressed(key_action1);
	bool pressed_m2 = this.isKeyPressed(key_action2);
	
	u32 m1Time = this.get_u32( "m1_heldTime");
	u32 m2Time = this.get_u32( "m2_heldTime");

	u32 m1ShotTicks = this.get_u32( "m1_shotTime" );
	u32 m2ShotTicks = this.get_u32( "m2_shotTime" );

	if (pressed_m1 && m1Time >= ship.firing_delay)
	{
		if (m1ShotTicks >= ship.firing_rate * moveVars.firingRateFactor)
		{
			CBitStream params;
			params.write_u16(this.getNetworkID()); //ownerID
			params.write_u8(1); //shot type

			uint bulletCount = ship.firing_burst;
			for (uint i = 0; i < bulletCount; i ++)
			{
				Vec2f firePos = Vec2f(8, -5.0f); //barrel pos
				firePos.RotateByDegrees(blobAngle);
				firePos += thisPos; //fire pos

				//as scout has a shotgun, randomize bullet speed a bit
				Vec2f fireVec = Vec2f(0.7f + (0.3f * _scout_logic_r.NextFloat()) ,0) * ship.shot_speed;
				f32 randomSpread = ship.firing_spread * (1.0f - (2.0f * _scout_logic_r.NextFloat()) ); //shot spread
				fireVec.RotateByDegrees(blobAngle + randomSpread); //shot vector
				fireVec += thisVel; //adds ship speed

				params.write_Vec2f(firePos); //shot position
				params.write_Vec2f(fireVec); //shot velocity
			}
			this.SendCommandOnlyServer(this.getCommandID(shot_command_ID), params);

			m1ShotTicks = 0;
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
	//m2ShotTicks++;
	this.set_u32( "m1_shotTime", m1ShotTicks );
	this.set_u32( "m2_shotTime", m2ShotTicks );

	//sound logic
	/*Vec2f vel = this.getVelocity();
	float posVelX = Maths::Abs(vel.x);
	float posVelY = Maths::Abs(vel.y);
	if(posVelX > 2.9f)
	{
		this.getSprite().SetEmitSoundVolume(3.0f);
	}
	else
	{
		this.getSprite().SetEmitSoundVolume(1.0f * (posVelX > posVelY ? posVelX : posVelY));
	}*/
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
        Vec2f vel(_scout_logic_r.NextFloat() * 3.0f, 0);
        vel.RotateBy(_scout_logic_r.NextFloat() * 360.0f);

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