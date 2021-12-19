
const string chargeTag = "holds_charge";

const string absoluteCharge_string = "absolute_charge";
const string absoluteMaxCharge_string = "absolute_max_charge";

shared class ChargeInfo
{
	s32 charge;
	s32 chargeMax;
	s32 chargeRegen;
	s32 chargeRate;

	ChargeInfo()
	{
		charge = 50; //charge amount
		chargeMax = 100; //max charge amount
		chargeRegen = 1; //amount per regen
		chargeRate = 0; //ticks per regen
	}
}

bool transferCharge(CBlob@ fromBlob, CBlob@ toBlob, s32 chargeAmount = 0)
{//this method returns whether or not it was able to transfer charge
	if (chargeAmount <= 0)
	{ return false; }

	ChargeInfo@ toChargeInfo;
	if (!toBlob.get( "chargeInfo", @toChargeInfo )) 
	{ return false; }
	ChargeInfo@ fromChargeInfo;
	if (!fromBlob.get( "chargeInfo", @fromChargeInfo )) 
	{ return false; }
	
	s32 toCharge = toChargeInfo.charge;
	s32 toMaxCharge = toBlob.get_s32(absoluteMaxCharge_string);
	s32 newToCharge = toCharge;

	s32 fromCharge = fromChargeInfo.charge;
	//s32 fromMaxCharge = fromBlob.get_s32(absoluteMaxCharge_string);
	s32 newFromCharge = fromCharge;

	if (fromCharge > 0 && toCharge < toMaxCharge)
	{
		s32 chargeSpace = toMaxCharge - toCharge;
		
		if (chargeSpace <= fromCharge)
		{
			if (chargeSpace >= chargeAmount)
			{
				newToCharge = toCharge + chargeAmount;
				toChargeInfo.charge = newToCharge;

				newFromCharge = fromCharge - chargeAmount;
				fromChargeInfo.charge = newFromCharge;
			}
			else
			{
				newToCharge = toMaxCharge;
				toChargeInfo.charge = newToCharge;

				chargeAmount = newToCharge - toCharge;

				newFromCharge = fromCharge - chargeAmount;
				fromChargeInfo.charge = newFromCharge;
			}
		}
		else
		{
			if (fromCharge >= chargeAmount)
			{
				newToCharge = toCharge + chargeAmount;
				toChargeInfo.charge = newToCharge;

				newFromCharge = fromCharge - chargeAmount;
				fromChargeInfo.charge = newFromCharge;
			}
			else
			{
				newFromCharge = 0;
				fromChargeInfo.charge = newFromCharge;

				chargeAmount = fromCharge;

				newToCharge = toCharge + chargeAmount;
				toChargeInfo.charge = newToCharge;
			}
		}
		updateAbsoluteCharge(fromBlob, newFromCharge);
		updateAbsoluteCharge(toBlob, newToCharge);
		return true;
    }

	return false;
}

bool addCharge(CBlob@ blob, s32 chargeAmount = 0) //increases charge
{//this method returns whether or not it was able to add charge
	
	ChargeInfo@ chargeInfo;
	if (chargeAmount <= 0 || !blob.get( "chargeInfo", @chargeInfo )) 
	{ return false; }
	
	s32 charge = chargeInfo.charge;
	s32 maxCharge = blob.get_s32(absoluteMaxCharge_string);

	s32 newCharge = charge;
        
	if (charge < maxCharge)
	{
		if (maxCharge - charge >= chargeAmount)
		{
			newCharge = charge + chargeAmount;
			chargeInfo.charge = newCharge;
		}
        else
		{
			newCharge = maxCharge;
			chargeInfo.charge = newCharge;
		}
		updateAbsoluteCharge(blob, newCharge);
		return true;
    }
	return false;
}

bool removeCharge(CBlob@ blob, s32 chargeAmount = 0, bool mustHaveEnough = false) //decreases charge
{//this method returns whether or not it was able to decrease charge
	
	ChargeInfo@ chargeInfo;
	if (chargeAmount <= 0 || !blob.get( "chargeInfo", @chargeInfo )) 
	{ return false; }
	
	s32 charge = chargeInfo.charge;

	s32 newCharge = charge;
        
	if (charge > 0)
	{
		if (charge >= chargeAmount)
		{
			newCharge = charge - chargeAmount;
			chargeInfo.charge = newCharge;
		}
        else if (!mustHaveEnough)
		{
			newCharge = 0;
			chargeInfo.charge = newCharge;
		}
		else
		{ return false; }

		updateAbsoluteCharge(blob, newCharge);
		return true;
    }
	return false;
}

void updateAbsoluteCharge(CBlob@ blob, s32 chargeAmount)
{
	blob.set_s32(absoluteCharge_string, chargeAmount);
	blob.Sync(absoluteCharge_string, true);
}
void updateAbsoluteMaxCharge(CBlob@ blob, s32 maxAmount)
{
	blob.set_s32(absoluteMaxCharge_string, maxAmount);
	blob.Sync(absoluteMaxCharge_string, true);
}

s32 findBatteries(CBlob@ blob)
{
	//insert inventory search code here
	return 0;
}