
#include "SpaceshipGlobal.as"
#include "CommonFX.as"

Random _barrier_logic_r(13337);

void onInit( CBlob@ this )
{
	this.Tag("barrier");
	this.getShape().SetGravityScale(0.0f);
}

void onInit( CSprite@ this )
{
	this.setRenderStyle(RenderStyle::additive);

	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null)
	{ return; }

	thisBlob.set_bool("active", true);
	thisBlob.set_u8("spriteTimer", 0);
}

void onTick( CSprite@ this )
{
	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null)
	{ return; }


	if (!thisBlob.get_bool("active"))
	{
		if (this.isVisible())
		{
			this.SetVisible(false);
		}
		return;
	}

	if (!this.isVisible())
	{ 
		this.SetVisible(true); 
		this.SetFrame(0);
	}

	u16 frame = this.getFrame();
	u8 spriteTimer = thisBlob.get_u8("spriteTimer");

	if (frame < 2)
	{
		if (spriteTimer >= 10)
		{
			this.SetFrame(frame + 1);
			thisBlob.set_u8("spriteTimer", 0);
		}
		else
		{
			thisBlob.set_u8("spriteTimer", spriteTimer + 1);
		}
	}

	
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	if (isClient())
	{
		makeTeamAura(worldPoint, this.getTeamNum(), this.getVelocity(), 40, 5.0f);
		this.getSprite().SetFrame(0);
		Sound::Play("individual_boom.ogg", worldPoint, 1.5f, 0.9f + ( 0.2f * _barrier_logic_r.NextFloat()));
	}

    return damage;
}