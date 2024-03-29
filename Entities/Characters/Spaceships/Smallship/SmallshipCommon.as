//Smallship Include

#include "SpaceshipGlobal.as"

namespace FighterParams
{
	//charge
	const ::f32 CHARGE_START = 0.1f; //percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 150; //max charge amount
	const ::s32 CHARGE_REGEN = 1; //amount per regen
	const ::s32 CHARGE_RATE = 20; //ticks per regen
	// ship general
	const ::f32 main_engine_force = 0.25f;
	const ::f32 secondary_engine_force = 0.18f;
	const ::f32 rcs_force = 0.15f;
	const ::f32 ship_turn_speed = 12.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 ship_drag = 0.1f; // air drag
	const ::f32 max_speed = 15.0f; // 0 = infinite speed
	//gun general
	const ::u32 firing_rate = 4; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 0; // ticks before first shot
	const ::u32 firing_spread = 1; // degrees
	const ::s32 firing_cost = 1; // charge cost
	const ::f32 shot_speed = 30.0f; // pixels per tick, 0 = instant
	const ::f32 shot_lifetime = 0.6f; // float, seconds
}

namespace InterceptorParams
{
	//charge
	const ::f32 CHARGE_START = 0.1f; //percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 220; //max charge amount
	const ::s32 CHARGE_REGEN = 0; //amount per regen
	const ::s32 CHARGE_RATE = 0; //ticks per regen
	// ship general
	const ::f32 main_engine_force = 0.4f;
	const ::f32 secondary_engine_force = 0.1f;
	const ::f32 rcs_force = 0.1f;
	const ::f32 ship_turn_speed = 10.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 ship_drag = 0.1f; // air drag
	const ::f32 max_speed = 20.0f; // 0 = infinite speed
	//gun general
	const ::u32 firing_rate = 2; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 15; // ticks before first shot
	const ::u32 firing_spread = 1; // degrees
	const ::s32 firing_cost = 1; // charge cost
	const ::f32 shot_speed = 30.0f; // pixels per tick, 0 = instant
	const ::f32 shot_lifetime = 0.4f; // float, seconds
}

namespace BomberParams
{
	//charge
	const ::f32 CHARGE_START = 0.0f; //percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 200; //max charge amount
	const ::s32 CHARGE_REGEN = 1; //amount per regen
	const ::s32 CHARGE_RATE = 120; //ticks per regen
	// ship general
	const ::f32 main_engine_force = 0.1f;
	const ::f32 secondary_engine_force = 0.07f;
	const ::f32 rcs_force = 0.05f;
	const ::f32 ship_turn_speed = 4.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 ship_drag = 0.2f; // air drag
	const ::f32 max_speed = 10.f; // 0 = infinite speed
	//gun general
	const ::u32 firing_rate = 10; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 0; // ticks before first shot
	const ::u32 firing_spread = 0; // degrees
	const ::s32 firing_cost = 5; // charge cost
	const ::f32 shot_speed = 12.0f; // pixels per tick, 0 = instant
	const ::f32 shot_lifetime = 1.0f; // float, seconds
}

namespace ScoutParams
{
	//charge
	const ::f32 CHARGE_START = 0.1f; //percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 300; //max charge amount
	const ::s32 CHARGE_REGEN = 3; //amount per regen
	const ::s32 CHARGE_RATE = 20; //ticks per regen
	// ship general
	const ::f32 main_engine_force = 0.15f;
	const ::f32 secondary_engine_force = 0.1f;
	const ::f32 rcs_force = 0.06f;
	const ::f32 ship_turn_speed = 5.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 ship_drag = 0.1f; // air drag
	const ::f32 max_speed = 15.f; // 0 = infinite speed
	//gun general
	const ::u32 firing_rate = 60; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 15; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 0; // ticks before first shot
	const ::u32 firing_spread = 6; // degrees
	const ::s32 firing_cost = 25; // charge cost
	const ::f32 shot_speed = 12.0f; // pixels per tick, 0 = instant
	const ::f32 shot_lifetime = 1.0f; // float, seconds
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
	s32 firing_cost; // charge cost
	f32 shot_speed; // pixels per tick, 0 = instant
	f32 shot_lifetime; // float, seconds

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
		firing_cost = 1;
		shot_speed = 3.0f;
		shot_lifetime = 1.0f;
	}
};

void fetchSmallshipInfo( int blobNameHash, 
float &out main_engine_force, float &out secondary_engine_force, float &out rcs_force, 
float &out ship_turn_speed, float &out ship_drag, float &out max_speed, 
u32 &out firing_rate, u32 &out firing_burst, u32 &out firing_delay, u32 &out firing_spread, s32 &out firing_cost, 
float &out shot_speed, float &out shot_lifetime )
{
	switch (blobNameHash)
	{
		case _interceptor:
		{
			main_engine_force 			= InterceptorParams::main_engine_force;
			secondary_engine_force 		= InterceptorParams::secondary_engine_force;
			rcs_force 					= InterceptorParams::rcs_force;
			ship_turn_speed 			= InterceptorParams::ship_turn_speed;
			ship_drag 					= InterceptorParams::ship_drag;
			max_speed 					= InterceptorParams::max_speed;
			
			firing_rate 				= InterceptorParams::firing_rate;
			firing_burst 				= InterceptorParams::firing_burst;
			firing_delay 				= InterceptorParams::firing_delay;
			firing_spread 				= InterceptorParams::firing_spread;
			firing_cost 				= InterceptorParams::firing_cost;
			shot_speed 					= InterceptorParams::shot_speed;
			shot_lifetime 				= InterceptorParams::shot_lifetime;
		}
		break;

		case _bomber:
		{
			main_engine_force 			= BomberParams::main_engine_force;
			secondary_engine_force 		= BomberParams::secondary_engine_force;
			rcs_force 					= BomberParams::rcs_force;
			ship_turn_speed 			= BomberParams::ship_turn_speed;
			ship_drag 					= BomberParams::ship_drag;
			max_speed 					= BomberParams::max_speed;
			
			firing_rate 				= BomberParams::firing_rate;
			firing_burst 				= BomberParams::firing_burst;
			firing_delay 				= BomberParams::firing_delay;
			firing_spread 				= BomberParams::firing_spread;
			firing_cost 				= BomberParams::firing_cost;
			shot_speed 					= BomberParams::shot_speed;
			shot_lifetime 				= BomberParams::shot_lifetime;
		}
		break;

		case _scout:
		{
			main_engine_force 			= ScoutParams::main_engine_force;
			secondary_engine_force 		= ScoutParams::secondary_engine_force;
			rcs_force 					= ScoutParams::rcs_force;
			ship_turn_speed 			= ScoutParams::ship_turn_speed;
			ship_drag 					= ScoutParams::ship_drag;
			max_speed 					= ScoutParams::max_speed;
			
			firing_rate 				= ScoutParams::firing_rate;
			firing_burst 				= ScoutParams::firing_burst;
			firing_delay 				= ScoutParams::firing_delay;
			firing_spread 				= ScoutParams::firing_spread;
			firing_cost 				= ScoutParams::firing_cost;
			shot_speed 					= ScoutParams::shot_speed;
			shot_lifetime 				= ScoutParams::shot_lifetime;
		}
		break;

		default: // _fighter, but default values
		{
			main_engine_force 			= FighterParams::main_engine_force;
			secondary_engine_force 		= FighterParams::secondary_engine_force;
			rcs_force 					= FighterParams::rcs_force;
			ship_turn_speed 			= FighterParams::ship_turn_speed;
			ship_drag 					= FighterParams::ship_drag;
			max_speed 					= FighterParams::max_speed;
			
			firing_rate 				= FighterParams::firing_rate;
			firing_burst 				= FighterParams::firing_burst;
			firing_delay 				= FighterParams::firing_delay;
			firing_spread 				= FighterParams::firing_spread;
			firing_cost 				= FighterParams::firing_cost;
			shot_speed 					= FighterParams::shot_speed;
			shot_lifetime 				= FighterParams::shot_lifetime;
		}
		break;
	}
}