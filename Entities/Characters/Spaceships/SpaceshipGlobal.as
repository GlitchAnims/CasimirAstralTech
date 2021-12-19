//Smallship Include

const string shot_command_ID = "shot";
const string hit_command_ID = "hit";

const string oldPosString = "old_pos";
const string firstTickString = "first_tick";
const string shot_lifetime_string = "shot_lifetime";

string getBulletName(u8 shotType = 0)
{
    string blobName = "bomb";
    switch (shotType)
	{
		case 0:
		{
			blobName = "orb";
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
		default: return blobName;
	}
    return blobName;
}