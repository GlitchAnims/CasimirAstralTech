
// some magic rules

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

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (this == null)
	{ return; }
	
    if (cmd == this.getCommandID(drain_charge_ID)) // client-to-server charge drain
    {
		if (!isServer())
		{ return; }
		
		u16 ownerID;
		s32 chargeAmount;
		
		if (!params.saferead_u16(ownerID)) return;
		if (!params.saferead_s32(chargeAmount)) return;

		CBlob@ ownerBlob = getBlobByNetworkID(ownerID);
		if (ownerBlob == null || ownerBlob.hasTag("dead"))
		{ return; }

		removeCharge(this, chargeAmount);
	}
	else if (cmd == this.getCommandID(transfer_charge_ID))
	{
		if (!isServer())
		{ return; }
		
		u16 fromBlobID; //always send this one first
		u16 toBlobID;
		s32 chargeAmount;
		
		if (!params.saferead_u16(fromBlobID)) return;
		if (!params.saferead_s32(chargeAmount)) return;

		CBlob@ fromBlob = getBlobByNetworkID(fromBlobID);
		if (fromBlob == null || fromBlob.hasTag("dead"))
		{ return; }

		while (params.saferead_u16(toBlobID)) //immediately stops if something fails
		{
			CBlob@ toBlob = getBlobByNetworkID(toBlobID);
			if (toBlob == null || toBlob.hasTag("dead"))
			{ continue; }

			transferCharge(fromBlob, toBlob, chargeAmount);
		}
	}
	else if (cmd == this.getCommandID(abscharge_update_ID))
	{
		s32 chargeAmount;

		if (!params.saferead_s32(chargeAmount)) return;

		this.set_s32(absoluteCharge_string, chargeAmount);
	}
	else if (cmd == this.getCommandID(max_abscharge_update_ID))
	{
		s32 newMaxCharge;

		if (!params.saferead_s32(newMaxCharge)) return;

		this.set_s32(absoluteMaxCharge_string, newMaxCharge);
	}
}