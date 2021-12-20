
#include "SpaceshipGlobal.as"
#include "CommonFX.as"
#include "GenericButtonCommon.as"
#include "BarrierCommon.as"

Random _barrier_logic_r(13337);

void onInit( CBlob@ this )
{
	this.Tag("barrier");
	this.getShape().SetGravityScale(0.0f);
	this.getShape().getConsts().mapCollisions = false;

	this.set_bool("active", true);
	this.set_u32("ownerBlobID", 0);

	AddIconToken("$shield_activate$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 23);
	AddIconToken("$shield_deactivate$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 27);

	this.addCommandID( shield_toggle_ID );
}

void onInit( CSprite@ this )
{
	this.setRenderStyle(RenderStyle::additive);

	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null)
	{ return; }

	thisBlob.set_u8("spriteTimer", 0);
}

void onTick( CSprite@ this )
{
	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null)
	{ return; }
	this.SetZ(-100.0f);

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

void onTick( CBlob@ this )
{
	if (!this.isAttached())
	{
		this.server_Die();
		return;
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

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	//if (!canSeeButtons(this, caller)) return;

	u32 ownerBlobID = this.get_u32("ownerBlobID");
	CBlob@ ownerBlob = getBlobByNetworkID(ownerBlobID);
	if (ownerBlobID == 0 || ownerBlob == null)
	{ 
		this.server_Die();
		return;
	}

	bool isShieldActive = this.get_bool("active");
	if (caller is ownerBlob)
	{
		string buttonIconString = "$shield_activate$";
		string buttonDescString = "Activate Shielding";
		if (isShieldActive)
		{
			buttonIconString = "$shield_deactivate$";
			buttonDescString = "Deactivate Shielding";
		}
		caller.CreateGenericButton(buttonIconString, Vec2f(0, -16), this, this.getCommandID(shield_toggle_ID), getTranslatedString(buttonDescString));
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID(shield_toggle_ID)) // 1 shot instance
    {
		this.set_bool("active", !this.get_bool("active"));
	}
}