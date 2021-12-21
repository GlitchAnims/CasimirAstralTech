
// Simple rules logic script

#include "PlayerInfo"
#define SERVER_ONLY

void onInit(CRules@ this)
{
	if (!this.exists("default class"))
	{
		this.set_string("default class", "builder");
	}
	PlayerInfo@[] playerList;
	this.set("playerList", playerList);

	updatePlayerList(this);
	//getPlayersCount()
}

void updatePlayerList( CRules@ this )
{
	int playerCount = getPlayersCount();
	if (playerCount <= 0)
	{ return; }

	PlayerInfo@[] playerList;
	if (!this.get( "playerList", @playerList )) 
	{ return; }

	for (int i = 0; i < playerCount; i++)
	{
		CPlayer@ newPlayer = getPlayer(i);
		PlayerInfo@ player = playerList[i];

		if (player )
	}
	
}

void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
	Respawn(this, player);
}

CBlob@ Respawn(CRules@ this, CPlayer@ player)
{
	if (player !is null)
	{
		// remove previous players blob
		CBlob @blob = player.getBlob();

		if (blob !is null)
		{
			CBlob @blob = player.getBlob();
			blob.server_SetPlayer(null);
			blob.server_Die();
		}

		CBlob @newBlob = server_CreateBlob(this.get_string("default class"), 0, getSpawnLocation(player));
		newBlob.server_SetPlayer(player);
		return newBlob;
	}

	return null;
}

Vec2f getSpawnLocation(CPlayer@ player)
{
	Vec2f[] spawns;

	if (getMap().getMarkers("blue spawn", spawns))
	{
		return spawns[ XORRandom(spawns.length) ];
	}
	else if (getMap().getMarkers("blue main spawn", spawns))
	{
		return spawns[ XORRandom(spawns.length) ];
	}

	return Vec2f(0, 0);
}

void onNewPlayerJoin( CRules@ this, CPlayer@ player )
{
	updatePlayerList
}

