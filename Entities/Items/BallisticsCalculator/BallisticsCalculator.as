void onInit(CBlob@ this)
{
	
}

void onTick(CBlob@ this)
{
	
}


void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{

}

void onDie(CBlob@ this)
{
	
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return byBlob.hasTag("player");
}