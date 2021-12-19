// character was placed in crate
void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.doTickScripts = true; // run scripts while in crate
	this.getMovement().server_SetActive(true);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	CShape@ shape = this.getShape();
	CShape@ oShape = blob.getShape();
	if (shape is null || oShape is null)
	{
		error("error: missing shape in runner doesCollideWithBlob");
		return false;
	}

	int thisTeamNum = this.getTeamNum();
	int targetTeamNum = blob.getTeamNum();

	bool targetIsMedium = blob.hasTag("mediumship");
	bool targetIsBig = blob.hasTag("bigship");

	if (thisTeamNum == targetTeamNum)
	{
		return false;
	}

	if (targetIsMedium || targetIsBig)
	{
		return false;
	}

	return true;
}
