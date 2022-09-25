// PodShield logic

#include "SpaceshipGlobal.as"
#include "ChargeCommon.as"
#include "PodCommon.as"
#include "SpaceshipVars.as"
#include "CommonFX.as"
#include "BarrierCommon.as"

Random _pod_logic_r(98444);
void onInit( CBlob@ this )
{
	this.Tag(denyChargeInputTag);
}

void onTick( CBlob@ this )
{
	u32 gameTime = getGameTime();

	if ((gameTime + this.getNetworkID()) % 90 == 0 || this.get_bool(quickSlotCheckBoolString)) //once every 3 seconds, server only
	{ 
		spawnAttachments(this);
		this.set_bool(quickSlotCheckBoolString, false);
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

	AttachmentPoint@ podSlot = attachments.getAttachmentPointByName("PODSLOT");

	if (podSlot != null)
	{
		Vec2f slotOffset = podSlot.offset;
		CBlob@ turret = podSlot.getOccupied();
		if (turret == null)
		{
			if (!isServer()) return; // server spawn blob
			CBlob@ blob = server_CreateBlob( "ship_sharelink" , teamNum, ownerPos + slotOffset);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				ownerBlob.server_AttachTo(blob, podSlot);
				blob.set_u16("ownerBlobID", ownerBlob.getNetworkID());
				blob.set_bool(enableButtonBoolString, false);
			}
		}
		else
		{
			turret.set_bool(activeBoolString, !ownerBlob.get_bool(isCarriedBoolString));
		}
	}
}