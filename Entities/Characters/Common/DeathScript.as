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
	if (!hasFX) return;
	
	u8 particleNum = 2;
	if (this.hasTag("hull"))
	{
		const u8 shipSize = this.get_u8(shipSizeString);
		switch (shipSize)
		{
			case _size_small:
			particleNum = 8; break;
			case _size_medium:
			particleNum = 20; break;
			case _size_big:
			case _size_structure:
			particleNum = 50; break;
		}
	}
	else
	{
		print("does not have hull tag");
	}

	genericShipExplosion( thisPos , particleNum );
}