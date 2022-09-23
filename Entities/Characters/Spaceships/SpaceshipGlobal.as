#include "AllHashCodes.as"
#include "SmallshipCommon.as"
#include "MediumshipCommon.as"

const string shot_command_ID = "shot";
const string hit_command_ID = "hit";
const string takeover_command_ID = "ship_takeover";
const string quit_ship_command_ID = "ship_quit";

const string oldPosString = "old_pos";
const string firstTickString = "first_tick";
const string clientFirstTickString = "client_first_tick";
const string shotLifetimeString = "shot_lifetime";
const string explosionFXBoolString = "does_explode";

const string shipSizeString = "ship_size";

const string smallTag = "small_ship";
const string mediumTag = "medium_ship";
const string bigTag = "big_ship";


const string isDockedBoolString = "is_docked";
const string isWarpBoolString = "is_warp";

const string activeBoolString = "active";
const string activeTimeString = "active_time";
const string enableButtonBoolString = "active_button";

enum ShipSizes
{
	_size_none = 0,
	_size_box,
	_size_small,
	_size_medium,
	_size_big,
	_size_structure,
};

u8 getShipSize( int blobNameHash )
{
	u8 shipSize = _size_none;
	switch (blobNameHash)
	{
		// pods
		case _pod_shield:
		case _pod_flak:
		case _pod_gatling:
		case _pod_artillery:
		case _pod_healgun:
		case _pod_generator:
		shipSize = _size_box; break;

		case _fighter:
		case _interceptor:
		case _bomber:
		case _scout:
		shipSize = _size_small; break;

		case _martyr:
		case _balthazar:
		case _foul:
		case _wanderer:
		shipSize = _size_medium; break;

		case _team_station:
		case _station_wing_nw:
		case _station_wing_ne:
		case _station_wing_se:
		case _station_wing_sw:
		shipSize = _size_structure; break;
	}

	return shipSize;
}

string getBulletName(u8 shotType = 0)
{
    string blobName = "bomb";
    switch (shotType)
	{
		case 0:
		{
			blobName = "shot_flak";
		}
		break;

		case 1:
		{
			blobName = "shot_gatling_basic";
		}
		break;

		case 2:
		{
			blobName = "shot_artillery_mini";
		}
		break;
		case 3:
		{
			blobName = "shot_artillery";
		}
		break;
		
		case 4:
		{
			blobName = "shot_tachyon";
		}
		break;

		case 5:
		{
			blobName = "shot_railgun";
		}
		break;

		case 6:
		{
			blobName = "missile_aa";
		}
		break;
		case 7:
		{
			blobName = "missile_aa";
		}
		break;
		case 8:
		{
			blobName = "missile_aa";
		}
		break;
		case 9:
		{
			blobName = "missile_aa";
		}
		break;

		case 10:
		{
			blobName = "ray_healbeam";
		}
		break;

		case 11:
		{
			blobName = "ray_pointdefense";
		}
		break;

		case 12:
		{
			blobName = "ray_neutronbeam";
		}
		break;

		default: return blobName;
	}
    return blobName;
}