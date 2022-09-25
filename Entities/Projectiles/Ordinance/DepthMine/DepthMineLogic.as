// Depth Mine logic

Random _mine_logic_r(11141);
void onInit( CBlob@ this )
{
	this.set_s8("ordinance_state", 0);

	this.getShape().SetGravityScale(0.0f);

	if (isServer())
	{
		float rotSpeed = _mine_logic_r.NextFloat() * 10.0f;
		this.setAngularVelocity(rotSpeed + 2.0f);
	}
}

void onTick( CBlob@ this )
{
	s8 ordinanceState = this.get_s8("ordinance_state");

	if (ordinanceState == 0)
	{
		int creationTicks = this.getTickSinceCreated();
		if (creationTicks >= 60) this.set_s8("ordinance_state", 1);
		return;
	}

	CMap@ map = getMap(); //standard map check
	if (map is null) return;

	Vec2f thisPos = this.getPosition();
	int teamNum = this.getTeamNum();

	bool targetFound = false;

	CBlob@[] blobsInRadius;
	map.getBlobsInRadius(thisPos, 64.0f, @blobsInRadius); //get a target
	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		CBlob@ b = blobsInRadius[i];
		if (b is null || b is this) continue;

		int blobTeamNum = b.getTeamNum();
		if (teamNum == blobTeamNum) continue;

		if (!b.hasTag("player")) continue;

		targetFound = true;
		break;
	}

	this.set_s8("ordinance_state", targetFound ? 2 : 1);
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	return false;
}