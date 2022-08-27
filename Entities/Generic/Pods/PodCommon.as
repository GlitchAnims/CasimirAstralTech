//Pod Include

#include "SpaceshipGlobal.as"

const string canCarryBoolString = "pod_can_carry";
const string isCarriedBoolString = "pod_carried";
const string carrierBlobNetidString = "pod_carrier_netid";

const string quickSlotCheckBoolString = "pod_slot_check";

const string pod_carry_toggle_ID = "pod_carry_toggle";

namespace PodShieldParams
{
	//charge
	const ::f32 CHARGE_START = 0.0f; //percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 300; //max charge amount
	const ::s32 CHARGE_REGEN = 1; //amount per regen
	const ::s32 CHARGE_RATE = 0; //ticks per regen

	//carrying
	const ::bool carry_can_turn = true; // whether or not the pod turns toward the carrier's aimpos
	const ::f32 carry_turn_speed = 1.0f; // carrying turn speed - degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 carry_vel = 0.15f; // carrying speed - velocity applied when carrying - lower = 'heavier' pod
	const ::f32 carry_dist = 16.0f; // minimum carrying distance - distance at which no more force is applied
}

namespace PodFlakParams
{
	//charge
	const ::f32 CHARGE_START = 0.0f; // percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 300; // max charge amount
	const ::s32 CHARGE_REGEN = 1; // amount per regen
	const ::s32 CHARGE_RATE = 0; // ticks per regen

	//carrying
	const ::bool carry_can_turn = false; // whether or not the pod turns toward the carrier's aimpos
	const ::f32 carry_turn_speed = 0.0f; // carrying turn speed - degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 carry_vel = 0.05f; // carrying speed - velocity applied when carrying - lower = 'heavier' pod
	const ::f32 carry_dist = 20.0f; // minimum carrying distance - distance at which no more force is applied
}

namespace PodGatlingParams
{
	//charge
	const ::f32 CHARGE_START = 0.0f; // percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 400; // max charge amount
	const ::s32 CHARGE_REGEN = 0; // amount per regen
	const ::s32 CHARGE_RATE = 0; // ticks per regen

	//carrying
	const ::bool carry_can_turn = false; // whether or not the pod turns toward the carrier's aimpos
	const ::f32 carry_turn_speed = 0.0f; // carrying turn speed - degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 carry_vel = 0.03f; // carrying speed - velocity applied when carrying - lower = 'heavier' pod
	const ::f32 carry_dist = 20.0f; // minimum carrying distance - distance at which no more force is applied
}

namespace PodArtilleryParams
{
	//charge
	const ::f32 CHARGE_START = 0.0f; // percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 400; // max charge amount
	const ::s32 CHARGE_REGEN = 0; // amount per regen
	const ::s32 CHARGE_RATE = 0; // ticks per regen

	//carrying
	const ::bool carry_can_turn = false; // whether or not the pod turns toward the carrier's aimpos
	const ::f32 carry_turn_speed = 0.0f; // carrying turn speed - degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 carry_vel = 0.02f; // carrying speed - velocity applied when carrying - lower = 'heavier' pod
	const ::f32 carry_dist = 25.0f; // minimum carrying distance - distance at which no more force is applied
}

namespace PodPDParams
{
	//charge
	const ::f32 CHARGE_START = 0.2f; // percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 200; // max charge amount
	const ::s32 CHARGE_REGEN = 1; // amount per regen
	const ::s32 CHARGE_RATE = 30; // ticks per regen

	//carrying
	const ::bool carry_can_turn = false; // whether or not the pod turns toward the carrier's aimpos
	const ::f32 carry_turn_speed = 0.0f; // carrying turn speed - degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 carry_vel = 0.08f; // carrying speed - velocity applied when carrying - lower = 'heavier' pod
	const ::f32 carry_dist = 16.0f; // minimum carrying distance - distance at which no more force is applied
}

namespace PodGeneratorParams
{
	//charge
	const ::f32 CHARGE_START = 0.1f; // percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 1000; // max charge amount
	const ::s32 CHARGE_REGEN = 10; // amount per regen
	const ::s32 CHARGE_RATE = 30; // ticks per regen

	//carrying
	const ::bool carry_can_turn = false; // whether or not the pod turns toward the carrier's aimpos
	const ::f32 carry_turn_speed = 0.0f; // carrying turn speed - degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 carry_vel = 0.02f; // carrying speed - velocity applied when carrying - lower = 'heavier' pod
	const ::f32 carry_dist = 20.0f; // minimum carrying distance - distance at which no more force is applied
}

class PodInfo
{
	bool forward_thrust;
	bool backward_thrust;
	bool port_thrust;
	bool starboard_thrust;

	//carrying
	bool carry_can_turn; // whether or not the pod turns toward the carrier's aimpos
	f32 carry_turn_speed; // carrying turn speed - degrees per tick, 0 = instant (30 ticks a second)
	f32 carry_vel; // carrying speed - velocity applied when carrying - lower = 'heavier' pod
	f32 carry_dist; // minimum carrying distance - distance at which no more force is applied

	PodInfo()
	{
		forward_thrust = false;
		backward_thrust = false;
		port_thrust = false;
		starboard_thrust = false;

		//carrying
		bool carry_can_turn = false;
		f32 carry_turn_speed = 0.0f;
		f32 carry_vel = 0.15f;
		f32 carry_dist = 16.0f;
	}
};

/*
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
}*/