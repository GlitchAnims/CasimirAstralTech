
const f32 secondsBeforeDeath = 10.0f;

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	if (shape != null)
	{
		shape.getConsts().mapCollisions = true;
		shape.SetGravityScale(0.0f);
	}

	this.set_u32("time_of_death", getGameTime() + (secondsBeforeDeath * getTicksASecond()));

	this.SetMapEdgeFlags(CBlob::map_collide_up | CBlob::map_collide_down | CBlob::map_collide_sides);
}

void onTick(CBlob@ this)
{
	if (isServer())
	{
		if (!this.isInInventory() && !this.isAttached())
		{
			if (getGameTime() >= this.get_u32("time_of_death"))
			{
				this.server_Die();
			}
			return;
		}
		else
		{
			this.set_u32("time_of_death", getGameTime() + (secondsBeforeDeath * getTicksASecond()));
		}
	}
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

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.doTickScripts = true;
}