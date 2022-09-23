
#include "AllHashCodes.as"

const string chargeTag = "holds_charge";
const string denyChargeInputTag = "deny_charge_input";

const string drain_charge_ID = "drain_charge";
const string transfer_charge_ID = "transfer_charge";

const string abscharge_update_ID = "update_charge";
const string max_abscharge_update_ID = "update_abscharge";

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
	CBitStream params;
	params.write_s32(chargeAmount);
	blob.SendCommand(blob.getCommandID(abscharge_update_ID), params);
}
void updateAbsoluteMaxCharge(CBlob@ blob, s32 maxAmount)
{
	CBitStream params;
	params.write_s32(maxAmount);
	blob.SendCommand(blob.getCommandID(max_abscharge_update_ID), params);
}

s32 findBatteries(CBlob@ blob)
{
	//insert inventory search code here
	return 0;
}

bool fetchChargeInfo( int blobNameHash, float &out chargeStart, s32 &out chargeMax, s32 &out chargeRegen, s32 &out chargeRate )
{
	switch(blobNameHash)
	{
		// smallships
		case _fighter:
		{
			chargeStart 	= 0.1f; 	//percentage charge to start with (0.0f - 1.0f)
			chargeMax 		= 150; 		//max charge amount
			chargeRegen 	= 1; 		//amount per regen
			chargeRate 		= 20; 		//ticks per regen
		}
		break;
		case _interceptor:
		{
			chargeStart 	= 0.1f;
			chargeMax 		= 220;
			chargeRegen 	= 0;
			chargeRate 		= 0;
		}
		break;
		case _bomber:
		{
			chargeStart 	= 0.0f;
			chargeMax 		= 200;
			chargeRegen 	= 1;
			chargeRate 		= 120;
		}
		break;
		case _scout:
		{
			chargeStart 	= 0.1f;
			chargeMax 		= 300;
			chargeRegen 	= 3;
			chargeRate 		= 20;
		}
		break;

		// mediumships
		case _martyr:
		{
			chargeStart 	= 0.3f;
			chargeMax 		= 500;
			chargeRegen 	= 9;
			chargeRate 		= 30;
		}
		break;
		case _balthazar:
		{
			chargeStart 	= 0.3f;
			chargeMax 		= 700;
			chargeRegen 	= 15;
			chargeRate 		= 30;
		}
		break;
		case _foul:
		{
			chargeStart 	= 0.1f;
			chargeMax 		= 300;
			chargeRegen 	= 3;
			chargeRate 		= 20;
		}
		break;
		case _wanderer:
		{
			chargeStart 	= 0.3f;
			chargeMax 		= 600;
			chargeRegen 	= 6;
			chargeRate 		= 30;
		}
		break;

		// structures
		case _team_station:
		{
			chargeStart 	= 1.0f;
			chargeMax 		= 3000;
			chargeRegen 	= 20;
			chargeRate 		= 30;
		}
		break;
		case _station_wing_nw:
		case _station_wing_ne:
		case _station_wing_se:
		case _station_wing_sw:
		{
			chargeStart 	= 1.0f;
			chargeMax 		= 3000;
			chargeRegen 	= 10;
			chargeRate 		= 30;
		}
		break;

		// pods
		case _pod_shield:
		{
			chargeStart 	= 0.0f;
			chargeMax 		= 300;
			chargeRegen 	= 1;
			chargeRate 		= 0;
		}
		break;
		case _pod_flak:
		{
			chargeStart 	= 0.0f;
			chargeMax 		= 300;
			chargeRegen 	= 1;
			chargeRate 		= 0;
		}
		break;
		case _pod_gatling:
		{
			chargeStart 	= 0.0f;
			chargeMax 		= 400;
			chargeRegen 	= 0;
			chargeRate 		= 0;
		}
		break;
		case _pod_artillery:
		{
			chargeStart 	= 0.0f;
			chargeMax 		= 400;
			chargeRegen 	= 0;
			chargeRate 		= 0;
		}
		break;
		case _pod_healgun:
		{
			chargeStart 	= 0.0f;
			chargeMax 		= 300;
			chargeRegen 	= 0;
			chargeRate 		= 0;
		}
		break;
		case _pod_generator:
		{
			chargeStart 	= 0.1f;
			chargeMax 		= 1000;
			chargeRegen 	= 10;
			chargeRate 		= 30;
		}
		break;
		
		default:
		return false; // did not find suitable candidate
	}
	return true;
}