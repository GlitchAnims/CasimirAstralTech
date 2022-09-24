#include "SpaceshipGlobal.as"
#include "Hitters.as"

void onInit( CBlob@ this )
{
	this.Tag(smallTag);
}
// character was placed in crate
void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.doTickScripts = true; // run scripts while in crate
	this.getMovement().server_SetActive(true);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	CShape@ shape = this.getShape();
	CShape@ oShape = blob.getShape();
	if (shape is null || oShape is null)
	{
		error("error: missing shape in runner doesCollideWithBlob");
		return false;
	}

	s8 thisTeamNum = this.getTeamNum();
	s8 blobTeamNum = blob.getTeamNum();

	u8 thisShipSize = this.get_u8(shipSizeString);
	u8 blobShipSize = blob.exists(shipSizeString) ? blob.get_u8(shipSizeString) : _size_none;

	const bool sameSize = thisShipSize == blobShipSize;
	const bool sameTeam = thisTeamNum == blobTeamNum;

	bool collides = true;
	switch (thisShipSize)
	{
		case _size_small:
		{
			collides = sameSize && !sameTeam;
		}
		break;
		case _size_medium:
		{
			collides = blobShipSize >= thisShipSize;
		}
		break;
	}
	
	return collides;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (!isServer() || !solid) return;

	if (this.hasTag("dead")) return; // dead bodies dont stomp

	Vec2f thisVel = this.getOldVelocity();
	Vec2f bVel = Vec2f_zero;
	float bSpeed = 0.0f;

	float damageMult = 0.7f;

	if (blob == null)
	{
		Vec2f wallVel = this.getVelocity();
		bVel = wallVel-thisVel;

		bSpeed = bVel.getLength();
		bSpeed *= damageMult;
		bSpeed -= 5.0f;

		if (bSpeed > 0.0f)
		{
			float enemydam = bSpeed;
			this.server_Hit(this, this.getPosition(), Vec2f_zero, enemydam, Hitters::fall);
		}
		return;
	}

	if (!doesCollideWithBlob(this,blob)) return; // phase thru

	s8 thisTeamNum = this.getTeamNum();
	s8 blobTeamNum = blob.getTeamNum();

	if (thisTeamNum == blobTeamNum) return; // don't damage your team

	u8 thisShipSize = this.get_u8(shipSizeString);
	u8 blobShipSize = blob.exists(shipSizeString) ? blob.get_u8(shipSizeString) : _size_none;

	if (blobShipSize > thisShipSize) return; // if enemy is bigger, do not deal damage
	if (blobShipSize < thisShipSize) damageMult *= 2.0f; // double damage if enemy is smaller

	Vec2f blobVel = blob.getOldVelocity();

	bVel = blobVel-thisVel;
	if (thisShipSize >= _size_medium) bVel *= 4.0f;
	
	bSpeed = bVel.getLength();
	bSpeed *= damageMult;
	bSpeed -= 5.0f;

	if (bSpeed > 0.0f)
	{
		float enemydam = bSpeed;

		if (enemydam > 0)
		{
			this.server_Hit(blob, this.getPosition(), Vec2f_zero, enemydam, Hitters::stomp);
		}
	}
}