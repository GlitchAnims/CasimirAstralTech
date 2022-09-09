const u8 maxCoins = 160;

void onTick( CRules@ this )
{
	if (getGameTime() % 90 == 0) // once every 3 seconds
	{
		u8 playerCount = getPlayersCount();
		if (playerCount <= 1) return; // also stop if player is alone

		for (uint i = 0; i < playerCount; i++)
		{
			CPlayer@ player = getPlayer(i);
			if (player is null) continue;

			u8 curCoins = player.getCoins();
			if (curCoins >= maxCoins) continue;
			player.server_setCoins(curCoins + 1);
		}
	}
}