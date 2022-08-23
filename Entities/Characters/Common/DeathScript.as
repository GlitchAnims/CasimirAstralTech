// Death script for all ships

#include "SpaceshipGlobal.as"
#include "SpaceshipVars.as"
#include "Hitters.as"
#include "CommonFX.as"

Random _death_script_r(99658);

void onInit( CBlob@ this )
{
	this.set_bool(explosionFXBoolString, true);
}

void onDie( CBlob@ this )
{
	Vec2f thisPos = this.getPosition();

	bool hasFX = this.get_bool(explosionFXBoolString);
	if (!hasFX)
	{ return; }

	if (this.hasTag("hull"))
	{
		if (this.hasTag(smallTag))
		{
			genericShipExplosion( thisPos , 8);
		}
		else if (this.hasTag(mediumTag))
		{
			genericShipExplosion( thisPos , 20);
		}
		else if (this.hasTag(bigTag))
		{
			genericShipExplosion( thisPos , 50);
		}
		else
		{
			genericShipExplosion( thisPos , 1);
			print("death and bypassed hull tag");
		}
	}
	else
	{
		genericShipExplosion( thisPos , 1);
		print("does not have hull tag");
	}
}