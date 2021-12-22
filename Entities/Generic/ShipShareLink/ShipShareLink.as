
#include "SpaceshipGlobal.as"
#include "CommonFX.as"
#include "GenericButtonCommon.as"
#include "BarrierCommon.as"
#include "ChargeCommon.as"

Random _barrier_logic_r(13337);

void onInit( CBlob@ this )
{
	this.Tag("barrier");
	this.getShape().SetGravityScale(0.0f);
	this.getShape().getConsts().mapCollisions = false;

	this.set_bool("active", false);
	this.set_u32("ownerBlobID", 0);

	AddIconToken("$shield_activate$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 23);
	AddIconToken("$shield_deactivate$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 27);
	AddIconToken("$shield_blocked$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 9);

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
	if (!isServer())
	{ return; }

	u32 ownerBlobID = this.get_u32("ownerBlobID");
	CBlob@ ownerBlob = getBlobByNetworkID(ownerBlobID);
	if (!this.isAttached() || ownerBlobID == 0 || ownerBlob == null)
	{ 
		this.server_Die();
		return;
	}

	if (!this.get_bool("active"))
	{ return; }

	ChargeInfo@ chargeInfo;
	if (!ownerBlob.get( "chargeInfo", @chargeInfo )) 
	{ return; }

	s32 regen = chargeInfo.chargeRegen;
	s32 rate = chargeInfo.chargeRate;

	if ((getGameTime() + this.getNetworkID()) % (rate + 1) != 0) //overcomplicated way to spread about the ticks
	{ return; }

	if (!removeCharge(ownerBlob, regen*2, true))
	{
		this.server_Die();
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

	if (isServer())
	{
		u32 ownerBlobID = this.get_u32("ownerBlobID");
		CBlob@ ownerBlob = getBlobByNetworkID(ownerBlobID);
		if (ownerBlobID == 0 || ownerBlob == null)
		{ 
			this.server_Die();
			return 0;
		}

		if (!removeCharge(ownerBlob, damage*5, true))
		{
			this.server_Die();
		}
	}

    return 0;
}

void onDie( CBlob@ this )
{
	if (!isClient())
	{ return; }

	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	const u16 particleNum = 10;

	Sound::Play("BarrierBreak.ogg", thisPos, 2.5f, 0.9f + ( 0.2f * _barrier_logic_r.NextFloat()));

	for (int i = 0; i < 10; i++)
    {
        Vec2f vel(_barrier_logic_r.NextFloat() * 10.0f, 0);
        vel.RotateBy(_barrier_logic_r.NextFloat() * 360.0f);

		u8 fileNum = XORRandom(3) + 1;
        CParticle@ p = ParticleAnimated("IceBlast"+ fileNum +".png", 
									thisPos + vel, 
									thisVel + vel, 
									float(XORRandom(360)), 
									1.5f + ( 2.0f * _barrier_logic_r.NextFloat()), 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if(p is null) continue; //bail if we stop getting particles
    	p.collides = false;
        p.damping = 0.85f;
		p.Z = -90.0f;
		p.lighting = false;
    }

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

	//enough charge for shield?
	s32 charge = ownerBlob.get_s32(absoluteCharge_string);
	s32 maxCharge = ownerBlob.get_s32(absoluteMaxCharge_string);

	bool isShieldActive = this.get_bool("active");
	bool enoughCharge = charge > (maxCharge * 0.25f); 
	if (caller is ownerBlob) //does not show button if not enough charge
	{
		string buttonIconString = "$shield_activate$";
		string buttonDescString = "Activate Shielding";
		if(isShieldActive)
		{
			buttonIconString = "$shield_deactivate$";
			buttonDescString = "Deactivate Shielding";
		}
		else if (!enoughCharge)//only denies button if shield isn't active
		{
			buttonDescString = "Cannot activate shield, charge below 25%!";
			caller.CreateGenericButton("$shield_blocked$", Vec2f(0, -12), this, 0, getTranslatedString(buttonDescString));
			return;
		}
		caller.CreateGenericButton(buttonIconString, Vec2f(0, -12), this, this.getCommandID(shield_toggle_ID), getTranslatedString(buttonDescString));
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID(shield_toggle_ID)) // 1 shot instance
    {
		u32 ownerBlobID = this.get_u32("ownerBlobID");
		CBlob@ ownerBlob = getBlobByNetworkID(ownerBlobID);
		if (ownerBlobID == 0 || ownerBlob == null)
		{ 
			this.server_Die();
			return;
		}
		
		this.set_bool("active", !this.get_bool("active"));
	}
}