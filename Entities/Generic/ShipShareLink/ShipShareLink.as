
#include "SpaceshipGlobal.as"
#include "CommonFX.as"
#include "GenericButtonCommon.as"
#include "ChargeCommon.as"

Random _ship_sharelink_r(68732);
const string link_toggle_ID = "link_toggle";

void onInit( CBlob@ this )
{
	this.getShape().SetGravityScale(0.0f);
	this.getShape().getConsts().mapCollisions = false;

	this.set_bool(activeBoolString, false);
	this.set_u32(activeTimeString, 0);
	this.set_u32("ownerBlobID", 0);

	AddIconToken("$link_toggle$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 11);

	this.addCommandID( link_toggle_ID );
}

void onTick( CBlob@ this )
{
	u32 ownerBlobID = this.get_u32("ownerBlobID");
	CBlob@ ownerBlob = getBlobByNetworkID(ownerBlobID);
	if (!this.isAttached() || ownerBlobID == 0 || ownerBlob == null)
	{ 
		this.server_Die();
		return;
	}

	CMap@ map = getMap(); //standard map check
	if (map is null)
	{ return; }

	Vec2f thisPos = this.getPosition();
	Vec2f ownerVel = ownerBlob.getVelocity();
	int teamNum = this.getTeamNum();

	const u32 activeTimeCap = 120;

	bool isActive = this.get_bool(activeBoolString);
	u32 activeTime = this.get_u32(activeTimeString);

	if (isActive)
	{
		if (activeTime < activeTimeCap)
		{ activeTime++; }
	}
	else
	{
		if (activeTime > 0)
		{ activeTime--; }
	}
	this.set_u32(activeTimeString, activeTime);

	const float maxRadius = ownerBlob.hasTag("npc") ? 80.0f : 100.0f;
	f32 shareLinkRadius = Maths::Clamp(float(activeTime) / activeTimeCap, 0.0f, 1.0f);
	shareLinkRadius *= maxRadius;

	if (isClient()) //aura visuals
	{
		if (shareLinkRadius > 1)
		{
			CBlob@[] blobsInRadius;
			map.getBlobsInRadius(thisPos, shareLinkRadius, @blobsInRadius); //charge aura
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob@ b = blobsInRadius[i];
				if (b is null)
				{ continue; }

				if (b.getTeamNum() != teamNum || b.hasTag("dead"))
				{ continue; }

				if (!b.hasTag(chargeTag) || b.hasTag(denyChargeInputTag))
				{ continue; }

				Vec2f blobPos = b.getPosition();
				makeEnergyLink(thisPos, blobPos, teamNum);
			} //for loop end
			
			u16 particleNum = shareLinkRadius / 6;
			makeTeamAura(thisPos, teamNum, ownerVel, particleNum, shareLinkRadius);
		}
	}

	if (isServer()) //charge mechanics
	{
		ChargeInfo@ chargeInfo;
		if (!ownerBlob.get( "chargeInfo", @chargeInfo )) 
		{ return; }

		s32 ownerCharge = ownerBlob.get_s32(absoluteCharge_string);
		const s32 chargeConsumption = 3; //charge lost every trigger
		const s32 chargeTransfer = 8; //charge transfered to each available target
		const s32 chargeRate = 15; //ticks per trigger

		if (shareLinkRadius > 1 && (getGameTime() + this.getNetworkID()) % chargeRate == 0 && ownerCharge >= chargeConsumption)
		{
			ownerCharge -= chargeConsumption;
			removeCharge(ownerBlob, chargeConsumption);

			CBlob@[] blobsInRadius;
			map.getBlobsInRadius(thisPos, shareLinkRadius, @blobsInRadius); //tent aura push
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				if (ownerCharge <= 0) //charge reduces per loop. Stop if ran out
				{ break; }
				CBlob@ b = blobsInRadius[i];
				if (b is null)
				{ continue; }

				if (b.getTeamNum() != teamNum || b.hasTag("dead") || !b.hasTag(chargeTag) || b.hasTag(denyChargeInputTag))
				{ continue; }

				s32 targetCharge = b.get_s32(absoluteCharge_string);
				s32 targetMaxCharge = b.get_s32(absoluteMaxCharge_string);
				if (targetCharge >= targetMaxCharge)
				{ continue; }

				s32 availableCharge = ownerCharge > chargeTransfer ? chargeTransfer : ownerCharge;
				s32 targetChargeSpace = targetMaxCharge - targetCharge;
				
				if (availableCharge <= targetChargeSpace)
				{
					ownerCharge -= availableCharge;
				}
				else
				{
					ownerCharge -= targetChargeSpace;
				}
			
				transferCharge(ownerBlob, b, chargeTransfer);
			}
		}
	}
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    return 0;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	u32 ownerBlobID = this.get_u32("ownerBlobID");
	CBlob@ ownerBlob = getBlobByNetworkID(ownerBlobID);
	if (ownerBlobID == 0 || ownerBlob == null)
	{ 
		this.server_Die();
		return;
	}

	bool isLinkActive = this.get_bool(activeBoolString);
	if ((caller is ownerBlob) || (ownerBlob.hasTag("npc") && caller.getTeamNum() == ownerBlob.getTeamNum()))
	{
		string buttonIconString = "$link_toggle$";
		string buttonDescString = "Activate Charge Field";
		if(isLinkActive)
		{
			buttonDescString = "Deactivate Charge Field";
		}
		caller.CreateGenericButton(buttonIconString, Vec2f(-10, -10), this, this.getCommandID(link_toggle_ID), getTranslatedString(buttonDescString));
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID(link_toggle_ID)) // 1 shot instance
    {
		u32 ownerBlobID = this.get_u32("ownerBlobID");
		CBlob@ ownerBlob = getBlobByNetworkID(ownerBlobID);
		if (ownerBlobID == 0 || ownerBlob == null)
		{ 
			this.server_Die();
			return;
		}
		
		this.set_bool(activeBoolString, !this.get_bool(activeBoolString));
	}
}