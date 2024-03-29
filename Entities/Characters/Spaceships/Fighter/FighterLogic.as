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

Random _fighter_logic_r(67532);
void onInit( CBlob@ this )
{
	this.set_u32( "m1_heldTime", 0 );
	this.set_u32( "m2_heldTime", 0 );

	this.set_u32( "m1_shotTime", 0 );
	this.set_u32( "m2_shotTime", 0 );

	this.set_bool( "leftCannonTurn", false);
	
	this.push("names to activate", "keg");
	this.push("names to activate", "nuke");

	//centered on items
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));
	
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
	//if (!isClient()) return;
	if (this.isInInventory()) return;
	if (!this.isMyPlayer()) return;

    SmallshipInfo@ ship;
	if (!this.get( "shipInfo", @ship )) return;
	
	CPlayer@ thisPlayer = this.getPlayer();
	if ( thisPlayer is null ) return;

	SpaceshipVars@ moveVars;
    if (!this.get( "moveVars", @moveVars )) return;

	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	f32 blobAngle = this.getAngleDegrees();
	blobAngle = (blobAngle+360.0f) % 360;

	//gun logic
	s32 m1ChargeCost = ship.firing_cost;
	const bool isShifting = this.get_bool("shifting");
	bool pressed_m1 = this.isKeyPressed(key_action1) && !isShifting;
	bool pressed_m2 = this.isKeyPressed(key_action2) && !isShifting;
	
	u32 m1Time = this.get_u32( "m1_heldTime");
	u32 m2Time = this.get_u32( "m2_heldTime");

	u32 m1ShotTicks = this.get_u32( "m1_shotTime" );
	u32 m2ShotTicks = this.get_u32( "m2_shotTime" );

	if (pressed_m1 && m1Time >= ship.firing_delay)
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
				Vec2f firePos = Vec2f(8, 4 * leftMult); //barrel pos
				firePos.RotateByDegrees(blobAngle);
				firePos += thisPos; //fire pos

				Vec2f fireVec = Vec2f(1.0f,0) * ship.shot_speed; 
				f32 randomSpread = ship.firing_spread * (1.0f - (2.0f * _fighter_logic_r.NextFloat()) ); //shot spread
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
	//empty
}