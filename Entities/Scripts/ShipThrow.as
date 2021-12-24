#include "ThrowCommon.as";

const f32 DEFAULT_THROW_VEL = 6.0f;

void onInit(CBlob@ this)
{
	if (!this.exists("names to activate"))
	{
		string[] names;
		this.set("names to activate", names);
	}

	this.addCommandID("activate/throw");
	// throw
	this.Tag("can throw");
	this.addCommandID("throw");
	this.set_f32("throw scale", 1.0f);
	this.set_bool("throw uses ourvel", true);
	this.set_f32("throw ourvel scale", 1.0f);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("throw"))
	{
		Vec2f pos = params.read_Vec2f();
		Vec2f vector = params.read_Vec2f();
		Vec2f vel = params.read_Vec2f();
		CBlob @carried = this.getCarriedBlob();

		if (carried !is null)
		{
			if (getNet().isServer() && !carried.hasTag("custom throw"))
			{
				DoThrow(this, carried, pos, vector, vel);
			}
			//this.Tag( carried.getName() + " done throw" );
		}
	}
}


// THROW

void DoThrow(CBlob@ this, CBlob@ carried, Vec2f pos, Vec2f vector, Vec2f selfVelocity)
{
	f32 ourvelscale = 0.0f;

	if (this.get_bool("throw uses ourvel"))
	{
		ourvelscale = this.get_f32("throw ourvel scale");
	}

	Vec2f vel = getThrowVelocity(this, vector, selfVelocity, ourvelscale);

	if (carried !is null)
	{
		if (carried.hasTag("medium weight"))
		{
			vel *= 0.6f;
		}
		else if (carried.hasTag("heavy weight"))
		{
			vel *= 0.3f;
		}

		if (carried.server_DetachFrom(this))
		{
			carried.setVelocity(vel);

			CShape@ carriedShape = carried.getShape();
			if (carriedShape !is null)
			{
				carriedShape.checkCollisionsAgain = true;
				carriedShape.ResolveInsideMapCollision();
			}
		}
	}
}

Vec2f getThrowVelocity(CBlob@ this, Vec2f vector, Vec2f selfVelocity, f32 this_vel_affect = 0.1f)
{
	const f32 minThrowDist = 8.0f;
	const f32 maxThrowDist = minThrowDist + 32.0f;
	Vec2f aimVec = vector;
	f32 aimLength = Maths::Min(aimVec.getLength(), maxThrowDist);

	Vec2f aimNorm = aimVec;
	aimNorm.Normalize();

	if (aimLength > minThrowDist)
	{ 
		aimLength -= minThrowDist;
	}

	f32 throwSpeed = (aimLength / maxThrowDist) * DEFAULT_THROW_VEL;
	Vec2f throwVel = aimNorm * throwSpeed;
	throwVel += selfVelocity; //adds owner velocity

	return throwVel;
}
