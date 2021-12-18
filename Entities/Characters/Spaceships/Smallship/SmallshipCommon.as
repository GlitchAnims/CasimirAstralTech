//Smallship Include

#include "SpaceshipGlobal.as"

namespace FighterParams
{
	//charge
	const ::f32 CHARGE_START = 0.3f; //percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 100; //max charge amount
	const ::s32 CHARGE_REGEN = 1; //amount per regen
	const ::s32 CHARGE_RATE = 10; //ticks per regen
	// ship general
	const ::f32 main_engine_force = 0.3f;
	const ::f32 secondary_engine_force = 0.1f;
	const ::f32 rcs_force = 0.1f;
	const ::f32 ship_turn_speed = 10.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 ship_drag = 0.1f; // air drag
	const ::f32 max_speed = 18.0f; // 0 = infinite speed
	//gun general
	const ::u32 firing_rate = 4; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 0; // ticks before first shot
	const ::u32 firing_spread = 1; // degrees
	const ::f32 shot_speed = 20.0f; // pixels per tick, won't fire if 0
}

namespace InterceptorParams
{
	//charge
	const ::f32 CHARGE_START = 0.3f; //percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 200; //max charge amount
	const ::s32 CHARGE_REGEN = 0; //amount per regen
	const ::s32 CHARGE_RATE = 0; //ticks per regen
	// ship general
	const ::f32 main_engine_force = 0.6f;
	const ::f32 secondary_engine_force = 0.05f;
	const ::f32 rcs_force = 0.05f;
	const ::f32 ship_turn_speed = 25.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 ship_drag = 0.1f; // air drag
	const ::f32 max_speed = 30.0f; // 0 = infinite speed
	//gun general
	const ::u32 firing_rate = 2; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 15; // ticks before first shot
	const ::u32 firing_spread = 1; // degrees
	const ::f32 shot_speed = 30.0f; // pixels per tick, won't fire if 0
}

namespace BomberParams
{
	//charge
	const ::f32 CHARGE_START = 0.0f; //percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 150; //max charge amount
	const ::s32 CHARGE_REGEN = 1; //amount per regen
	const ::s32 CHARGE_RATE = 20; //ticks per regen
	// ship general
	const ::f32 main_engine_force = 0.2f;
	const ::f32 secondary_engine_force = 0.1f;
	const ::f32 rcs_force = 0.1f;
	const ::f32 ship_turn_speed = 6.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 ship_drag = 0.5f; // air drag
	const ::f32 max_speed = 10.f; // 0 = infinite speed
	//gun general
	const ::u32 firing_rate = 10; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 10; // ticks before first shot
	const ::u32 firing_spread = 0; // degrees
	const ::f32 shot_speed = 10.0f; // pixels per tick, won't fire if 0
}

namespace ScoutParams
{
	//charge
	const ::f32 CHARGE_START = 0.5f; //percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 300; //max charge amount
	const ::s32 CHARGE_REGEN = 3; //amount per regen
	const ::s32 CHARGE_RATE = 20; //ticks per regen
	// ship general
	const ::f32 main_engine_force = 0.15f;
	const ::f32 secondary_engine_force = 0.1f;
	const ::f32 rcs_force = 0.06f;
	const ::f32 ship_turn_speed = 8.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 ship_drag = 0.1f; // air drag
	const ::f32 max_speed = 15.f; // 0 = infinite speed
	//gun general
	const ::u32 firing_rate = 60; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 15; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 0; // ticks before first shot
	const ::u32 firing_spread = 5; // degrees
	const ::f32 shot_speed = 15.0f; // pixels per tick, won't fire if 0
}

class SmallshipInfo
{
	bool forward_thrust;
	bool backward_thrust;
	bool port_thrust;
	bool starboard_thrust;

	// ship general
	f32 main_engine_force;
	f32 secondary_engine_force;
	f32 rcs_force;
	f32 ship_turn_speed; // degrees per tick, 0 = instant (30 ticks a second)
	f32 ship_drag; // air drag
	f32 max_speed; // 0 = infinite speed
	//gun general
	u32 firing_rate; // ticks per shot, won't fire if 0
	u32 firing_burst; // bullets per shot, won't fire if 0
	u32 firing_delay; // ticks before first shot
	u32 firing_spread; // degrees
	f32 shot_speed; // pixels per tick, 0 = instant

	SmallshipInfo()
	{
		forward_thrust = false;
		backward_thrust = false;
		port_thrust = false;
		starboard_thrust = false;

		//ship general
		main_engine_force = 3.0f;
		secondary_engine_force = 2.0f;
		rcs_force = 1.0f;
		ship_turn_speed = 1.0f;
		ship_drag = 0.1f;
		max_speed = 200.0f;
		//gun general
		firing_rate = 2;
		firing_burst = 1;
		firing_delay = 1;
		firing_spread = 1;
		shot_speed = 3.0f;
	}
};