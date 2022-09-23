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
	// uh oh
}

void onTick( CBlob@ this )
{
	// vvvvvvvvvvvvvv SERVER-SIDE ONLY vvvvvvvvvvvvvvvvvvv
	if (!isServer()) return;

	u32 gameTime = getGameTime();

	if ((gameTime + this.getNetworkID()) % 90 == 0) //once every 3 seconds, server only
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

	AttachmentPoint@ podSlot = attachments.getAttachmentPointByName("PODSLOT");

	if (podSlot != null)
	{
		Vec2f slotOffset = podSlot.offset;
		CBlob@ turret = podSlot.getOccupied();
		if (turret == null)
		{
			CBlob@ blob = server_CreateBlob( "shield_full" , teamNum, ownerPos + slotOffset);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				ownerBlob.server_AttachTo(blob, podSlot);
				blob.set_u32("ownerBlobID", ownerBlob.getNetworkID());
				blob.set_u16(shieldModeNumString, 2);
			}
		}
	}
}