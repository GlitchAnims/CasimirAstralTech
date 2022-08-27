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
	this.set_s32(absoluteCharge_string, 0);
	this.set_s32(absoluteMaxCharge_string, 0);
	if (isServer())
	{
		ChargeInfo chargeInfo;
		chargeInfo.charge 			= PodHealgunParams::CHARGE_START * PodHealgunParams::CHARGE_MAX;
		chargeInfo.chargeMax 		= PodHealgunParams::CHARGE_MAX;
		chargeInfo.chargeRegen 		= PodHealgunParams::CHARGE_REGEN;
		chargeInfo.chargeRate 		= PodHealgunParams::CHARGE_RATE;
		this.set("chargeInfo", @chargeInfo);
	}

	PodInfo pod;
	pod.carry_can_turn 		= PodHealgunParams::carry_can_turn;
	pod.carry_turn_speed 	= PodHealgunParams::carry_turn_speed;
	pod.carry_vel 			= PodHealgunParams::carry_vel;
	pod.carry_dist 			= PodHealgunParams::carry_dist;
	this.set("podInfo", @pod);

	this.getShape().SetRotationsAllowed(pod.carry_can_turn);
}

void onTick( CBlob@ this )
{
	// vvvvvvvvvvvvvv SERVER-SIDE ONLY vvvvvvvvvvvvvvvvvvv
	if (!isServer()) return;

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
			CBlob@ blob = server_CreateBlob( "turret_healgun" , teamNum, ownerPos + slotOffset);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				ownerBlob.server_AttachTo(blob, podSlot);
				blob.set_u32("ownerBlobID", ownerBlob.getNetworkID());
				blob.set_bool("automatic", true);
			}
		}
		else
		{
			turret.set_bool("automatic", !ownerBlob.get_bool(isCarriedBoolString));
		}
	}
}