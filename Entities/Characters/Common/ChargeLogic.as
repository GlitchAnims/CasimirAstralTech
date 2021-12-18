#define SERVER_ONLY

#include "ChargeCommon.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
	this.set_bool("firstTick", true);
}

void onTick(CBlob@ this)
{
    ChargeInfo@ chargeInfo;
	if (!this.get( "chargeInfo", @chargeInfo )) 
	{ return; }

	if (this.get_bool("firstTick")) //set starting charge
	{
		updateAbsoluteCharge(this, chargeInfo.charge);
		updateAbsoluteMaxCharge(this, chargeInfo.chargeMax);
		this.set_bool("firstTick", false);
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