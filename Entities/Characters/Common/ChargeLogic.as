#include "SpaceshipGlobal.as"
#include "ChargeCommon.as"

void onInit(CBlob@ this)
{
	this.Tag(chargeTag);
	this.getCurrentScript().removeIfTag = "dead";
	this.set_bool("chargeFirstTick", true);
	this.addCommandID( drain_charge_ID ); //SpaceshipGlobal.as
	this.addCommandID( transfer_charge_ID ); //SpaceshipGlobal.as
}

void onTick(CBlob@ this)
{
	if (!isServer()) //SERVER ONLY
	{ return; }

    ChargeInfo@ chargeInfo;
	if (!this.get( "chargeInfo", @chargeInfo )) 
	{ return; }

	if (this.get_bool("chargeFirstTick")) //set starting charge
	{
		updateAbsoluteCharge(this, chargeInfo.charge);
		updateAbsoluteMaxCharge(this, chargeInfo.chargeMax);
		this.set_bool("chargeFirstTick", false);
	}

	s32 updateRate = chargeInfo.chargeRate; //if rate is 0, pause onTick forever
	if (updateRate <= 0)
	{ 
		this.getCurrentScript().tickFrequency = 0;
		return;
	}

	if ( (getGameTime() + this.getNetworkID()) % 30 == 0 ) //fixed at once a second
	{
		//increase max charge accordingly
		s32 maxCharge = chargeInfo.chargeMax;
		s32 newMaxCharge = maxCharge + findBatteries(this);

		if (this.get_s32(absoluteMaxCharge_string) != newMaxCharge)
		{
			updateAbsoluteMaxCharge(this, newMaxCharge);
			s32 charge = chargeInfo.charge;
			if (charge > newMaxCharge) //if max charge lowers below current charge, fix charge
			{
				chargeInfo.charge = newMaxCharge;
				updateAbsoluteCharge(this, newMaxCharge);
			}
		}
    }

	if ( (getGameTime() + this.getNetworkID()) % updateRate == 0 )
	{
		//now regen charge
		s32 chargeRegen = chargeInfo.chargeRegen;

		addCharge(this, chargeRegen);
    }
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
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
}