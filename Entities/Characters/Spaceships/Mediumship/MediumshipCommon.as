//Smallship Include

#include "SpaceshipGlobal.as"

namespace MartyrParams
{
	//charge
	const ::f32 CHARGE_START = 0.3f; //percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 500; //max charge amount
	const ::s32 CHARGE_REGEN = 3; //amount per regen
	const ::s32 CHARGE_RATE = 10; //ticks per regen
	// ship general
	const ::f32 main_engine_force = 0.02f;
	const ::f32 secondary_engine_force = 0.1f;
	const ::f32 rcs_force = 0.1f;
	const ::f32 ship_turn_speed = 3.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 ship_drag = 1.0f; // air drag
	const ::f32 max_speed = 5.0f; // 0 = infinite speed
	//gun general
	const ::u32 firing_rate = 4; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 0; // ticks before first shot
	const ::u32 firing_spread = 0; // degrees
	const ::s32 firing_cost = 6; // charge cost
	const ::f32 shot_speed = 18.0f; // pixels per tick, 0 = instant
	const ::f32 shot_lifetime = 1.3f; // float, seconds
}

class MediumshipInfo
{
	bool forward_thrust;
	bool backward_thrust;
	bool port_thrust;
	bool portBow_thrust;
	bool portQuarter_thrust;
	bool starboard_thrust;
	bool starboardBow_thrust;
	bool starboardQuarter_thrust;

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
	s32 firing_cost; // charge cost
	f32 shot_speed; // pixels per tick, 0 = instant
	f32 shot_lifetime; // float, seconds

	MediumshipInfo()
	{
		forward_thrust = false;
		backward_thrust = false;
		port_thrust = false;
		portBow_thrust = false;
		portQuarter_thrust = false;
		starboard_thrust = false;
		starboardBow_thrust = false;
		starboardQuarter_thrust = false;

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
		firing_cost = 1;
		shot_speed = 3.0f;
		shot_lifetime = 1.0f;
	}
};