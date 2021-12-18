shared class ChargeInfo
{
	s32 charge;
	s32 maxCharge;
	s32 chargeRegen;
	s32 chargeRate;

	ChargeInfo()
	{
		charge = 0; //charge amount
		chargeMax = 100; //max charge amount
		chargeRegen = 1; //amount per regen
		chargeRate = 30; //ticks per regen
	}
}