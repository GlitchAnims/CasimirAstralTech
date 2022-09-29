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
	const ::f32 secondary_engine_force = 0.015f;
	const ::f32 rcs_force = 0.01f;
	const ::f32 ship_turn_speed = 1.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 ship_drag = 0.2f; // air drag
	const ::f32 max_speed = 5.0f; // 0 = infinite speed
	//gun general
	const ::u32 firing_rate = 5; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 0; // ticks before first shot
	const ::u32 firing_spread = 0; // degrees
	const ::s32 firing_cost = 6; // charge cost
	const ::f32 shot_speed = 18.0f; // pixels per tick, won't fire if 0
	const ::f32 shot_lifetime = 1.1f; // float, seconds
}

namespace BalthazarParams
{
	//charge
	const ::f32 CHARGE_START = 0.3f; //percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 700; //max charge amount
	const ::s32 CHARGE_REGEN = 5; //amount per regen
	const ::s32 CHARGE_RATE = 10; //ticks per regen
	// ship general
	const ::f32 main_engine_force = 0.02f;
	const ::f32 secondary_engine_force = 0.018f;
	const ::f32 rcs_force = 0.015f;
	const ::f32 ship_turn_speed = 1.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 ship_drag = 0.2f; // air drag
	const ::f32 max_speed = 4.0f; // 0 = infinite speed
	//gun general
	const ::u32 firing_rate = 9; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 0; // ticks before first shot
	const ::u32 firing_spread = 2; // degrees
	const ::s32 firing_cost = 8; // charge cost
	const ::f32 shot_speed = 10.0f; // pixels per tick, 0 = instant
	const ::f32 shot_lifetime = 2.4f; // float, seconds
}

namespace FoulParams
{
	//charge
	const ::f32 CHARGE_START = 0.3f; //percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 700; //max charge amount
	const ::s32 CHARGE_REGEN = 5; //amount per regen
	const ::s32 CHARGE_RATE = 10; //ticks per regen
	// ship general
	const ::f32 main_engine_force = 0.02f;
	const ::f32 secondary_engine_force = 0.018f;
	const ::f32 rcs_force = 0.015f;
	const ::f32 ship_turn_speed = 1.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 ship_drag = 0.2f; // air drag
	const ::f32 max_speed = 4.0f; // 0 = infinite speed
	//gun general
	const ::u32 firing_rate = 9; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 0; // ticks before first shot
	const ::u32 firing_spread = 2; // degrees
	const ::s32 firing_cost = 8; // charge cost
	const ::f32 shot_speed = 10.0f; // pixels per tick, 0 = instant
	const ::f32 shot_lifetime = 2.4f; // float, seconds
}

namespace WandererParams
{
	//charge
	const ::f32 CHARGE_START = 0.3f; //percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 600; //max charge amount
	const ::s32 CHARGE_REGEN = 2; //amount per regen
	const ::s32 CHARGE_RATE = 10; //ticks per regen
	// ship general
	const ::f32 main_engine_force = 0.018f;
	const ::f32 secondary_engine_force = 0.012f;
	const ::f32 rcs_force = 0.01f;
	const ::f32 ship_turn_speed = 0.8f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 ship_drag = 0.2f; // air drag
	const ::f32 max_speed = 5.0f; // 0 = infinite speed
	//gun general
	const ::u32 firing_rate = 15; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 3; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 30; // ticks before first shot
	const ::u32 firing_spread = 15; // degrees
	const ::s32 firing_cost = 15; // charge cost
	const ::f32 shot_speed = 15.0f; // pixels per tick, won't fire if 0
	const ::f32 shot_lifetime = 1.2f; // float, seconds
}

namespace FaradayParams
{
	//charge
	const ::f32 CHARGE_START = 0.3f; //percentage charge to start with (0.0f - 1.0f)
	const ::s32 CHARGE_MAX = 600; //max charge amount
	const ::s32 CHARGE_REGEN = 2; //amount per regen
	const ::s32 CHARGE_RATE = 10; //ticks per regen
	// ship general
	const ::f32 main_engine_force = 0.06f;
	const ::f32 secondary_engine_force = 0.04f;
	const ::f32 rcs_force = 0.2f;
	const ::f32 ship_turn_speed = 3.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 ship_drag = 0.2f; // air drag
	const ::f32 max_speed = 8.0f; // 0 = infinite speed
	//gun general
	const ::u32 firing_rate = 15; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 3; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 30; // ticks before first shot
	const ::u32 firing_spread = 15; // degrees
	const ::s32 firing_cost = 15; // charge cost
	const ::f32 shot_speed = 15.0f; // pixels per tick, won't fire if 0
	const ::f32 shot_lifetime = 1.2f; // float, seconds
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

void fetchMediumshipInfo( int blobNameHash, 
float &out main_engine_force, float &out secondary_engine_force, float &out rcs_force, 
float &out ship_turn_speed, float &out ship_drag, float &out max_speed, 
u32 &out firing_rate, u32 &out firing_burst, u32 &out firing_delay, u32 &out firing_spread, s32 &out firing_cost, 
float &out shot_speed, float &out shot_lifetime )
{
	switch (blobNameHash)
	{
		case _balthazar:
		{
			main_engine_force 			= BalthazarParams::main_engine_force;
			secondary_engine_force 		= BalthazarParams::secondary_engine_force;
			rcs_force 					= BalthazarParams::rcs_force;
			ship_turn_speed 			= BalthazarParams::ship_turn_speed;
			ship_drag 					= BalthazarParams::ship_drag;
			max_speed 					= BalthazarParams::max_speed;
			
			firing_rate 				= BalthazarParams::firing_rate;
			firing_burst 				= BalthazarParams::firing_burst;
			firing_delay 				= BalthazarParams::firing_delay;
			firing_spread 				= BalthazarParams::firing_spread;
			firing_cost 				= BalthazarParams::firing_cost;
			shot_speed 					= BalthazarParams::shot_speed;
			shot_lifetime 				= BalthazarParams::shot_lifetime;
		}
		break;

		case _foul:
		{
			main_engine_force 			= FoulParams::main_engine_force;
			secondary_engine_force 		= FoulParams::secondary_engine_force;
			rcs_force 					= FoulParams::rcs_force;
			ship_turn_speed 			= FoulParams::ship_turn_speed;
			ship_drag 					= FoulParams::ship_drag;
			max_speed 					= FoulParams::max_speed;
			
			firing_rate 				= FoulParams::firing_rate;
			firing_burst 				= FoulParams::firing_burst;
			firing_delay 				= FoulParams::firing_delay;
			firing_spread 				= FoulParams::firing_spread;
			firing_cost 				= FoulParams::firing_cost;
			shot_speed 					= FoulParams::shot_speed;
			shot_lifetime 				= FoulParams::shot_lifetime;
		}
		break;

		case _wanderer:
		{
			main_engine_force 			= WandererParams::main_engine_force;
			secondary_engine_force 		= WandererParams::secondary_engine_force;
			rcs_force 					= WandererParams::rcs_force;
			ship_turn_speed 			= WandererParams::ship_turn_speed;
			ship_drag 					= WandererParams::ship_drag;
			max_speed 					= WandererParams::max_speed;
			
			firing_rate 				= WandererParams::firing_rate;
			firing_burst 				= WandererParams::firing_burst;
			firing_delay 				= WandererParams::firing_delay;
			firing_spread 				= WandererParams::firing_spread;
			firing_cost 				= WandererParams::firing_cost;
			shot_speed 					= WandererParams::shot_speed;
			shot_lifetime 				= WandererParams::shot_lifetime;
		}
		break;

		case _faraday:
		{
			main_engine_force 			= FaradayParams::main_engine_force;
			secondary_engine_force 		= FaradayParams::secondary_engine_force;
			rcs_force 					= FaradayParams::rcs_force;
			ship_turn_speed 			= FaradayParams::ship_turn_speed;
			ship_drag 					= FaradayParams::ship_drag;
			max_speed 					= FaradayParams::max_speed;
			
			firing_rate 				= FaradayParams::firing_rate;
			firing_burst 				= FaradayParams::firing_burst;
			firing_delay 				= FaradayParams::firing_delay;
			firing_spread 				= FaradayParams::firing_spread;
			firing_cost 				= FaradayParams::firing_cost;
			shot_speed 					= FaradayParams::shot_speed;
			shot_lifetime 				= FaradayParams::shot_lifetime;
		}
		break;

		default: // _martyr, but default values
		{
			main_engine_force 			= MartyrParams::main_engine_force;
			secondary_engine_force 		= MartyrParams::secondary_engine_force;
			rcs_force 					= MartyrParams::rcs_force;
			ship_turn_speed 			= MartyrParams::ship_turn_speed;
			ship_drag 					= MartyrParams::ship_drag;
			max_speed 					= MartyrParams::max_speed;
			
			firing_rate 				= MartyrParams::firing_rate;
			firing_burst 				= MartyrParams::firing_burst;
			firing_delay 				= MartyrParams::firing_delay;
			firing_spread 				= MartyrParams::firing_spread;
			firing_cost 				= MartyrParams::firing_cost;
			shot_speed 					= MartyrParams::shot_speed;
			shot_lifetime 				= MartyrParams::shot_lifetime;
		}
		break;
	}
}