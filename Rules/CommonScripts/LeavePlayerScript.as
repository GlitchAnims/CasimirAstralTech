#include "SpaceshipGlobal.as"

void onPlayerLeave( CRules@ this, CPlayer@ player )
{
	CBlob@ blob = player.getBlob();
	if(blob !is null && isServer())
	{
		blob.server_SetPlayer(null);
		if (blob.hasTag(smallTag)) blob.server_Die();
	}
}