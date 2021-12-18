//Smallship Include

const string shot_command_ID = "shot";
const string hit_command_ID = "hit";

namespace FlakParams
{
	const ::f32 turret_turn_speed = 10.0f; // degrees per tick, 0 = instant (30 ticks a second)

	const ::u32 firing_rate = 8; // ticks per shot, won't fire if 0
	const ::u32 firing_burst = 1; // bullets per shot, won't fire if 0
	const ::u32 firing_delay = 0; // ticks before first shot
	const ::u32 firing_spread = 4; // degrees
	const ::f32 shot_speed = 10.0f; // pixels per tick, won't fire if 0
}

class TurretInfo
{
	f32 turret_turn_speed; // degrees per tick, 0 = instant (30 ticks a second)

	u32 firing_rate; // ticks per shot, won't fire if 0
	u32 firing_burst; // bullets per shot, won't fire if 0
	u32 firing_delay; // ticks before first shot
	u32 firing_spread; // degrees
	f32 shot_speed; // pixels per tick, 0 = instant

	TurretInfo()
	{
		turret_turn_speed = 1.0f;

		firing_rate = 2;
		firing_burst = 1;
		firing_delay = 1;
		firing_spread = 1;
		shot_speed = 3.0f;
	}
};