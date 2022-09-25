//Turret Include

#include "SpaceshipGlobal.as"

Random _turret_logic_r(98444);
namespace FlakParams
{
	const ::f32 turret_turn_speed = 8.0f; // degrees per tick, 0 = instant (30 ticks a second)

	const ::u32 firing_rate = 8; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 0; // ticks before first shot
	const ::u32 firing_spread = 12; // degrees
	const ::s32 firing_cost = 2; // charge cost
	const ::f32 shot_speed = 10.0f; // pixels per tick, won't fire if 0
}

namespace GatlingParams
{
	const ::f32 turret_turn_speed = 2.0f; // degrees per tick, 0 = instant (30 ticks a second)

	const ::u32 firing_rate = 3; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 2; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 30; // ticks before first shot
	const ::u32 firing_spread = 5; // degrees
	const ::s32 firing_cost = 2; // charge cost
	const ::f32 shot_speed = 20.0f; // pixels per tick, won't fire if 0
}

namespace ArtilleryParams
{
	const ::f32 turret_turn_speed = 1.5f; // degrees per tick, 0 = instant (30 ticks a second)

	const ::u32 firing_rate = 30; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 0; // ticks before first shot
	const ::u32 firing_spread = 1; // degrees
	const ::s32 firing_cost = 6; // charge cost
	const ::f32 shot_speed = 8.0f; // pixels per tick, won't fire if 0
}

namespace PDParams
{
	const ::f32 turret_turn_speed = 12.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 turret_targeting_range = 128.0f; // radius, in pixels. Loses target if beyond range

	const ::u32 firing_rate = 1; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 0; // ticks before first shot
	const ::u32 firing_spread = 0; // degrees
	const ::s32 firing_cost = 1; // charge cost
	const ::f32 shot_speed = 1.0f; // pixels per tick, won't fire if 0
}

namespace HealgunParams
{
	const ::f32 turret_turn_speed = 1.5f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 turret_targeting_range = 128.0f; // radius, in pixels. Loses target if beyond range

	const ::u32 firing_rate = 2; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 0; // ticks before first shot
	const ::u32 firing_spread = 0; // degrees
	const ::s32 firing_cost = 2; // charge cost
	const ::f32 shot_speed = 1.0f; // pixels per tick, won't fire if 0
}

class TurretInfo
{
	f32 turret_turn_speed; // degrees per tick, 0 = instant (30 ticks a second)
	f32 turret_targeting_range; // radius, in pixels

	u32 firing_rate; // ticks per shot, won't fire if 0
	u32 firing_burst; // bullets per shot, won't fire if 0
	u32 firing_delay; // ticks before first shot
	u32 firing_spread; // degrees
	s32 firing_cost; // charge cost
	f32 shot_speed; // pixels per tick, 0 = instant

	u16 auto_target_ID; //current target for automatic mode

	TurretInfo()
	{
		turret_turn_speed = 1.0f;
		turret_targeting_range = 512.0f;

		firing_rate = 2;
		firing_burst = 1;
		firing_delay = 1;
		firing_spread = 1;
		firing_cost = 1;
		shot_speed = 3.0f;

		auto_target_ID = 0;
	}
};

void turretFire(CBlob@ ownerBlob, u8 shotType = 0, Vec2f blobPos = Vec2f_zero, Vec2f blobVel = Vec2f_zero, float lifeTime = 1.0f)
{
	if (ownerBlob == null || ownerBlob.hasTag("dead"))
	{ return; }
	if (blobPos == Vec2f_zero || blobVel == Vec2f_zero)
	{ return; }

	string blobName = getBulletName(shotType);

	CBlob@ blob = server_CreateBlob( blobName , ownerBlob.getTeamNum(), blobPos);
	if (blob !is null)
	{
		blob.IgnoreCollisionWhileOverlapped( ownerBlob );
		blob.SetDamageOwnerPlayer( ownerBlob.getDamageOwnerPlayer() );
		blob.setVelocity( blobVel );
		blob.set_f32(shotLifetimeString, lifeTime);
	}
}

void turretSetup( CBlob@ this )
{
	this.set_u16("ownerBlobID", 0);

	this.set_u32( "space_heldTime", 0 );
	this.set_u32( "space_shotTime", 0 );

	this.set_bool( "automatic", false);
	
	this.Tag("npc");

	CShape@ shape = this.getShape();
	if (shape != null)
	{
		this.getShape().SetRotationsAllowed(false); //no spinning
		this.getShape().SetGravityScale(0);
		this.getShape().getConsts().mapCollisions = false;

		this.getShape().getConsts().net_threshold_multiplier = 1.0f;
	}

	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right | CBlob::map_collide_nodeath);
}

void turretDeath( CBlob@ this )
{
	// empty
}