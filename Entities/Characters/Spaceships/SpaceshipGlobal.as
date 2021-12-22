const string shot_command_ID = "shot";
const string hit_command_ID = "hit";
const string takeover_command_ID = "ship_takeover";
const string quit_ship_command_ID = "ship_quit";

const string oldPosString = "old_pos";
const string firstTickString = "first_tick";
const string shotLifetimeString = "shot_lifetime";

const string smallTag = "small_ship";
const string mediumTag = "medium_ship";
const string bigTag = "big_ship";

const string activeBoolString = "active";
const string activeTimeString = "active_time";

string getBulletName(u8 shotType = 0)
{
    string blobName = "bomb";
    switch (shotType)
	{
		case 0:
		{
			blobName = "flak_shot";
		}
		break;

		case 1:
		{
			blobName = "gatling_basicshot";
		}
		break;

		case 2:
		{
			blobName = "artillery_minishot";
		}
		break;
		case 3:
		{
			blobName = "artillery_minishot";
		}
		break;
		case 4:
		{
			blobName = "artillery_minishot";
		}
		break;

		case 5:
		{
			blobName = "railgun_shot";
		}
		break;
		default: return blobName;
	}
    return blobName;
}