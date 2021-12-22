//Turret Include

#include "SpaceshipGlobal.as"

namespace FlakParams
{
	const ::f32 turret_turn_speed = 8.0f; // degrees per tick, 0 = instant (30 ticks a second)

	const ::u32 firing_rate = 8; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 0; // ticks before first shot
	const ::u32 firing_spread = 12; // degrees
	const ::s32 firing_cost = 2; // charge cost
	const ::f32 shot_speed = 5.0f; // pixels per tick, won't fire if 0
}

class TurretInfo
{
	f32 turret_turn_speed; // degrees per tick, 0 = instant (30 ticks a second)

	u32 firing_rate; // ticks per shot, won't fire if 0
	u32 firing_burst; // bullets per shot, won't fire if 0
	u32 firing_delay; // ticks before first shot
	u32 firing_spread; // degrees
	s32 firing_cost; // charge cost
	f32 shot_speed; // pixels per tick, 0 = instant

	TurretInfo()
	{
		turret_turn_speed = 1.0f;

		firing_rate = 2;
		firing_burst = 1;
		firing_delay = 1;
		firing_spread = 1;
		firing_cost = 1;
		shot_speed = 3.0f;
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