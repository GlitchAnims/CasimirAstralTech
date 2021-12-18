#include "ChargeCommon.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{
    if(!isServer())
    { return; }

    ChargeInfo@ chargeInfo;
	if (!this.get( "chargeInfo", @chargeInfo )) 
	{ return; }

	if (getGameTime() % 4 == 0)
	{
		//now regen charge
		s32 charge = chargeInfo.charge;
		s32 maxCharge = chargeInfo.maxCharge;
		
        u8 adjustedChargeRegenRate = this.get_u8("charge regen rate");
        
		if (charge < maxCharge)
		{
			if (maxCharge - charge >= adjustedChargeRegenRate)
				chargeInfo.charge += adjustedChargeRegenRate;
            else
                chargeInfo.charge = maxCharge;
        }

    }
}
