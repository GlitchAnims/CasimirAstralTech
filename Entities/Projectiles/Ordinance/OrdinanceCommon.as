//Missile Include

#include "SpaceshipGlobal.as"

const string targetNetIDString = "target_net_ID";
const string hasTargetTicksString = "has_target_ticks";

const string has_ordinance_update_ID = "has_ordinance_update";
const string homing_target_update_ID = "homing_target_update";

const string lastAbsoluteVelString = "last_absoulte_vel";

const string quickHomingTag = "quick_homing";

namespace AAMissileParams
{
	// movement general
	const ::f32 main_engine_force = 0.35f;
	const ::f32 secondary_engine_force = 0.18f;
	const ::f32 rcs_force = 0.15f;
	const ::f32 ship_turn_speed = 14.0f; // degrees per tick, 0 = instant (30 ticks a second)
	const ::f32 max_speed = 16.0f; // 0 = infinite speed

	//targeting
	const ::u32 lose_target_ticks = 90; //ticks until targetblob is null again
}

class MissileInfo
{
	bool forward_thrust;
	bool backward_thrust;
	bool port_thrust;
	bool starboard_thrust;

	// movement general
	f32 main_engine_force;
	f32 secondary_engine_force;
	f32 rcs_force;
	f32 ship_turn_speed; // degrees per tick, 0 = instant (30 ticks a second)
	f32 max_speed; // 0 = infinite speed

	//targeting
	CBlob@ target_blob;
	u32 lose_target_ticks; //ticks until targetblob is null again

	MissileInfo()
	{
		forward_thrust = false;
		backward_thrust = false;
		port_thrust = false;
		starboard_thrust = false;

		//movement general
		main_engine_force = 3.0f;
		secondary_engine_force = 2.0f;
		rcs_force = 1.0f;
		ship_turn_speed = 1.0f;
		max_speed = 200.0f;

		//targeting
		lose_target_ticks = 30;
	}
};

shared class LauncherInfo
{
	u32 cooldown;
	u32 max_cooldown;
	bool has_ordinance;
	u8 stab_delay;
	u8 fletch_cooldown;
	u8 ordinance_type;

	u8 legolas_arrows;
	u8 legolas_time;

	bool grappling;
	u16 grapple_id;
	f32 grapple_ratio;
	f32 cache_angle;
	Vec2f grapple_pos;
	Vec2f grapple_vel;

	u8[] launchableOrdinance;
	u16[] found_targets_id;

	LauncherInfo()
	{
		cooldown = 0;
		max_cooldown = 0;
		has_ordinance = false;
		stab_delay = 0;
		fletch_cooldown = 0;
		ordinance_type = OrdinanceType::aa;
		grappling = false;

		const u8[] ord = {0, 1, 2, 3};
		launchableOrdinance.opAssign(ord);
	}
};

shared class OrdinanceLaunchInfo
{
	u8 ordinance;
	u16 target_ID;
	Vec2f launch_pos;
	Vec2f launch_vec;

	OrdinanceLaunchInfo()
	{
		ordinance = 0;
		target_ID = 0;
		launch_pos = Vec2f_zero;
		launch_vec = Vec2f_zero;
	}
};

void turnOffAllThrust( MissileInfo@ missile )
{
	missile.forward_thrust = false;
	missile.backward_thrust = false;
	missile.port_thrust = false;
	missile.starboard_thrust = false;
}

namespace OrdinanceType
{
	enum type
	{
		aa = 0,
		cruise,
		emp,
		flare,
		count
	};
}

const string[] ordinanceTypeNames = { "mat_missile_aa",
                                  "mat_missile_cruise",
                                  "mat_missile_emp",
                                  "mat_missile_flare"
                                };
const string[] ordinanceBlobNames = { "missile_aa",
                                  "missile_cruise",
                                  "missile_emp",
                                  "missile_flare"
                                };

const string[] ordinanceNames = { "AA Missile",
                              "Cruise Missile",
                              "EMP Missile",
                              "Flare"
                            };

const string[] ordinanceIcons = { "$MissileAA$",
                              "$MissileCruise$",
                              "$MissileEMP$",
                              "$MissileFlare$"
                            };


bool hasOrdinance(CBlob@ this)
{
	LauncherInfo@ launcher;
	if (!this.get("launcherInfo", @launcher))
	{ return false; }

	if (launcher.ordinance_type >= 0 && launcher.ordinance_type < ordinanceTypeNames.length)
	{
		return this.getBlobCount(ordinanceTypeNames[launcher.ordinance_type]) > 0;
	}
	return false;
}

bool hasOrdinance(CBlob@ this, u8 ordinanceType)
{
	return ordinanceType < OrdinanceType::count && this.getBlobCount(ordinanceTypeNames[ordinanceType]) > 0;
}

bool hasAnyOrdinance(CBlob@ this)
{
	for (uint i = 0; i < OrdinanceType::count; i++)
	{
		if (hasOrdinance(this, i))
		{
			return true;
		}
	}
	return false;
}

void SetOrdinanceType(CBlob@ this, const u8 type)
{
	LauncherInfo@ launcher;
	if (!this.get("launcherInfo", @launcher))
	{ return; }

	launcher.ordinance_type = type;
}

u8 getOrdinanceType(CBlob@ this)
{
	LauncherInfo@ launcher;
	if (!this.get("launcherInfo", @launcher))
	{ return 0; }

	return launcher.ordinance_type;
}

u32 getOrdinanceCooldown(u8 type)
{
	switch (type)
	{
		case OrdinanceType::aa: return 15;

		case OrdinanceType::cruise: return 300;

		case OrdinanceType::emp: return 40;

		case OrdinanceType::flare: return 5;

		//default: return 30;
	}

	return 30;
}

void updateOrdinanceTarget( CBlob@ this, u16 newTargetNetID = 0, bool resetTimer = false)
{
	CBitStream params;
	params.write_u16(newTargetNetID);
	params.write_bool(resetTimer);
	this.SendCommand(this.getCommandID(homing_target_update_ID), params);
}

void updateOrdinanceAvailability( CBlob@ this, bool hasOrd = false )
{
	if (isServer())
	{
		CBitStream params;
		params.write_bool(hasOrd);
		this.SendCommand(this.getCommandID(has_ordinance_update_ID), params);
	}
	else
	{
		this.set_bool("has_ord", hasOrd);
	}
}