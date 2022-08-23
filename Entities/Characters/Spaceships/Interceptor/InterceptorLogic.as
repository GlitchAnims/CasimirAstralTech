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

Random _interceptor_logic_r(44440);
void onInit( CBlob@ this )
{
	this.set_s32(absoluteCharge_string, 0);
	this.set_s32(absoluteMaxCharge_string, 0);
	if (isServer())
	{
		ChargeInfo chargeInfo;
		chargeInfo.charge 			= InterceptorParams::CHARGE_START * InterceptorParams::CHARGE_MAX;
		chargeInfo.chargeMax 		= InterceptorParams::CHARGE_MAX;
		chargeInfo.chargeRegen 		= InterceptorParams::CHARGE_REGEN;
		chargeInfo.chargeRate 		= InterceptorParams::CHARGE_RATE;
		this.set("chargeInfo", @chargeInfo);
	}
	
	SmallshipInfo ship;
	ship.main_engine_force 			= InterceptorParams::main_engine_force;
	ship.secondary_engine_force 	= InterceptorParams::secondary_engine_force;
	ship.rcs_force 					= InterceptorParams::rcs_force;
	ship.ship_turn_speed 			= InterceptorParams::ship_turn_speed;
	ship.ship_drag 					= InterceptorParams::ship_drag;
	ship.max_speed 					= InterceptorParams::max_speed;
	
	ship.firing_rate 				= InterceptorParams::firing_rate;
	ship.firing_burst 				= InterceptorParams::firing_burst;
	ship.firing_delay 				= InterceptorParams::firing_delay;
	ship.firing_spread 				= InterceptorParams::firing_spread;
	ship.firing_cost 				= InterceptorParams::firing_cost;
	ship.shot_speed 				= InterceptorParams::shot_speed;
	ship.shot_lifetime 				= InterceptorParams::shot_lifetime;
	this.set("shipInfo", @ship);
	
	//keys setup

	this.set_u32( "m1_heldTime", 0 );
	this.set_u32( "m2_heldTime", 0 );

	this.set_u32( "m1_shotTime", 0 );
	this.set_u32( "m2_shotTime", 500 );

	this.set_bool( "leftCannonTurn", false);

	this.set_bool("shifted", false);
	this.set_bool("grav_bubble", false);
	
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
	// vvvvvvvvvvvvvv CLIENT-SIDE ONLY vvvvvvvvvvvvvvvvvvv
	//if (!isClient()) return;
	if (this.isInInventory()) return;
	if (!isClient()) return;

	const bool is_myPlayer = this.isMyPlayer();

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

	s32 thisCharge = this.get_s32(absoluteCharge_string);

	//gun logic
	s32 m1ChargeCost = ship.firing_cost;
	s32 m2ChargeCost = 10;
	bool pressed_m1 = this.isKeyPressed(key_action1) && !this.get_bool("grav_bubble"); //if bubble is in effect, force false
	bool pressed_m2 = this.isKeyPressed(key_action2);
	
	u32 m1Time = this.get_u32( "m1_heldTime");
	u32 m2Time = this.get_u32( "m2_heldTime");

	u32 m1ShotTicks = this.get_u32( "m1_shotTime" );
	u32 m2ShotTicks = this.get_u32( "m2_shotTime" );

	f32 m1FiringDelay = ship.firing_delay;

	if (is_myPlayer && pressed_m1 && m1Time >= m1FiringDelay)
	{
		if (m1ShotTicks >= ship.firing_rate * moveVars.firingRateFactor)
		{
			bool leftCannon = this.get_bool( "leftCannonTurn" );
			this.set_bool( "leftCannonTurn", !leftCannon);

			CBitStream params;
			params.write_u16(this.getNetworkID()); //ownerID
			params.write_u8(1); //shot type
			params.write_f32(ship.shot_lifetime); //shot lifetime
			params.write_s32(m1ChargeCost); //charge drain

			uint bulletCount = ship.firing_burst;
			for (uint i = 0; i < bulletCount; i ++)
			{
				f32 leftMult = leftCannon ? 1.0f : -1.0f;
				Vec2f firePos = Vec2f(8, 5.5f * leftMult); //barrel pos
				firePos.RotateByDegrees(blobAngle);
				firePos += thisPos; //fire pos

				Vec2f fireVec = Vec2f(1.0f,0) * ship.shot_speed; 
				f32 randomSpread = ship.firing_spread * (1.0f - (2.0f * _interceptor_logic_r.NextFloat()) ); //shot spread
				fireVec.RotateByDegrees(blobAngle + randomSpread); //shot vector
				fireVec += thisVel; //adds ship speed

				params.write_Vec2f(firePos); //shot position
				params.write_Vec2f(fireVec); //shot velocity
			}
			this.SendCommandOnlyServer(this.getCommandID(shot_command_ID), params);

			m1ShotTicks = 0;
		}
	}

	if ( (pressed_m2 || m2ShotTicks < 30) && thisCharge >= m2ChargeCost )
	{
		if (is_myPlayer && getGameTime() % 10 == 0)
		{
			CBitStream params;
			params.write_u16(this.getNetworkID()); //ownerID
			params.write_s32(m2ChargeCost);
			this.SendCommandOnlyServer(this.getCommandID(drain_charge_ID), params);
		}

		moveVars.engineFactor *= 0.0f;
		moveVars.maxSpeedFactor *= 1.5f;
		moveVars.dragFactor *= 10.0f;

		Vec2f aimVec = this.getAimPos() - thisPos;
		Vec2f aimNorm = aimVec;
		aimNorm.Normalize();
		
		this.setVelocity(thisVel + (aimNorm*1.5f));

		if (!this.get_bool("grav_bubble"))
		{
			this.set_bool("grav_bubble", true);
			m2ShotTicks = 0;
		}
	}
	else
	{
		this.set_bool("grav_bubble", false);
	}

	//timer logic
	if (pressed_m1) //this one's special because of Interceptor's gatling windup
	{
		if (m1Time < m1FiringDelay)
		{ m1Time++; }
	}
	else 
	{
		if (m1Time > 0)
		{ m1Time--; }
	}
	
	if (pressed_m2)
	{
		if (m2Time < 500)
		{ m2Time++; }
	}
	else { m2Time = 0; }
	this.set_u32( "m1_heldTime", m1Time );
	this.set_u32( "m2_heldTime", m2Time );

	if (m1ShotTicks < 500)
	{
		m1ShotTicks++;
	}
	if (m2ShotTicks < 500)
	{
		m2ShotTicks++;
	}
	this.set_u32( "m1_shotTime", m1ShotTicks );
	this.set_u32( "m2_shotTime", m2ShotTicks );

	f32 windupPercentage = float(m1Time) / m1FiringDelay;
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
	genericShipExplosion( this.getPosition() , 8);
}