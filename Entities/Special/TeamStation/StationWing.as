// Station Wing logic

#include "SpaceshipGlobal.as"
#include "Hitters.as"
#include "ChargeCommon.as"
#include "CommonFX.as"

Random _TDM_ruins_r(67656);

void onInit(CBlob@ this)
{
	this.set_s32(absoluteCharge_string, 0);
	this.set_s32(absoluteMaxCharge_string, 0);
	if (isServer())
	{
		ChargeInfo chargeInfo;
		chargeInfo.charge 			= 1.0f;
		chargeInfo.chargeMax 		= 3000;
		chargeInfo.chargeRegen 		= 10;
		chargeInfo.chargeRate 		= 30;
		this.set("chargeInfo", @chargeInfo);
	}
	this.Tag(denyChargeInputTag);

	//this.getShape().SetStatic(true);
	this.getShape().getConsts().mapCollisions = false;

	this.Tag(bigTag);

	this.getShape().SetGravityScale(0);

	if (isServer())
	{ spawnAttachments(this); }

	this.getSprite().SetZ(-60.0f);   // push behind station core
}

void onTick(CBlob@ this)
{
	// vvvvvvvvvvvvvv SERVER-SIDE ONLY vvvvvvvvvvvvvvvvvvv
	if (!isServer()) return;

	u32 gameTime = getGameTime();

	bool attached = this.isAttached();
	u32 ownerBlobID = this.get_u32("ownerBlobID");
	CBlob@ ownerBlob = getBlobByNetworkID(ownerBlobID);
	if (!attached || ownerBlobID == 0 || ownerBlob == null)
	{ 
		this.server_Die();
		return;
	}
	
	if ((gameTime + this.getNetworkID()) % 900 == 0) //once every 30 seconds, server only
	{ 
		spawnAttachments(this);
	}
}

void spawnAttachments(CBlob@ ownerBlob)
{
	if (ownerBlob == null)
	{ return; }

	CAttachment@ attachments = ownerBlob.getAttachments();
	if (attachments == null)
	{ return; }
	
	Vec2f ownerPos = ownerBlob.getPosition();
	int teamNum = ownerBlob.getTeamNum();

	AttachmentPoint@ flakslot1 = attachments.getAttachmentPointByName("AUTOFLAKSLOT1");
	AttachmentPoint@ flakslot2 = attachments.getAttachmentPointByName("AUTOFLAKSLOT2");

	AttachmentPoint@ gatlingslot1 = attachments.getAttachmentPointByName("AUTOGATLINGSLOT1");
	AttachmentPoint@ gatlingslot2 = attachments.getAttachmentPointByName("AUTOGATLINGSLOT2");

	AttachmentPoint@ pdslot1 = attachments.getAttachmentPointByName("AUTOPDSLOT1");

	if (flakslot1 != null)
	{
		Vec2f slotOffset = flakslot1.offset;
		CBlob@ turret = flakslot1.getOccupied();
		if (turret == null)
		{
			CBlob@ blob = server_CreateBlob( "turret_flak" , teamNum, ownerPos + slotOffset);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				ownerBlob.server_AttachTo(blob, flakslot1);
				blob.set_u32("ownerBlobID", ownerBlob.getNetworkID());
				blob.set_bool("automatic", true);
			}
		}
	}
	if (flakslot2 != null)
	{
		Vec2f slotOffset = flakslot2.offset;
		CBlob@ turret = flakslot2.getOccupied();
		if (turret == null)
		{
			CBlob@ blob = server_CreateBlob( "turret_flak" , teamNum, ownerPos + slotOffset);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				ownerBlob.server_AttachTo(blob, flakslot2);
				blob.set_u32("ownerBlobID", ownerBlob.getNetworkID());
				blob.set_bool("automatic", true);
			}
		}
	}

	if (gatlingslot1 != null)
	{
		Vec2f slotOffset = gatlingslot1.offset;
		CBlob@ turret = gatlingslot1.getOccupied();
		if (turret == null)
		{
			CBlob@ blob = server_CreateBlob( "turret_gatling" , teamNum, ownerPos + slotOffset);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				ownerBlob.server_AttachTo(blob, gatlingslot1);
				blob.set_u32("ownerBlobID", ownerBlob.getNetworkID());
				blob.set_bool("automatic", true);
			}
		}
	}
	if (gatlingslot2 != null)
	{
		Vec2f slotOffset = gatlingslot2.offset;
		CBlob@ turret = gatlingslot2.getOccupied();
		if (turret == null)
		{
			CBlob@ blob = server_CreateBlob( "turret_gatling" , teamNum, ownerPos + slotOffset);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				ownerBlob.server_AttachTo(blob, gatlingslot2);
				blob.set_u32("ownerBlobID", ownerBlob.getNetworkID());
				blob.set_bool("automatic", true);
			}
		}
	}

	if (pdslot1 != null)
	{
		Vec2f slotOffset = pdslot1.offset;
		CBlob@ turret = pdslot1.getOccupied();
		if (turret == null)
		{
			CBlob@ blob = server_CreateBlob( "turret_pd" , teamNum, ownerPos + slotOffset);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				ownerBlob.server_AttachTo(blob, pdslot1);
				blob.set_u32("ownerBlobID", ownerBlob.getNetworkID());
				blob.set_bool("automatic", true);
			}
		}
	}
	
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    if (customData == Hitters::suicide)
	{
		return 0;
	}
	else if (customData == Hitters::arrow)
	{
		damage *= 0.25;
	}

	if (isClient())
	{
		makeHullHitSparks( worldPoint, 15 );
	}

    return damage;
}