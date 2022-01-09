#include "AllHashCodes.as";

void onInit(CBlob@ this)
{
	if (getNet().isServer())
	{
		this.set_u16('decay time', 45);
	}

	u8 stackQuantity = 1;
	switch (this.getName().getHash())
	{
		case _mat_missile_aa:
		stackQuantity = 20;
		break;

		case _mat_missile_cruise:
		stackQuantity = 1;
		break;

		case _mat_missile_emp:
		stackQuantity = 5;
		break;

		case _mat_missile_flare:
		stackQuantity = 30;
		break;
	}
	this.maxQuantity = stackQuantity;

	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
