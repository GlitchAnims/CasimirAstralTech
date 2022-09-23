// TDM Ruins logic

#include "SpaceshipGlobal.as"
#include "ClassSelectMenu.as"
#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "RespawnCommandCommon.as"
#include "GenericButtonCommon.as"
#include "Hitters.as"
#include "ChargeCommon.as"
#include "CommonFX.as"

Random _TDM_ruins_r(67656);

void onInit(CBlob@ this)
{
	this.Tag(denyChargeInputTag);

	this.CreateRespawnPoint("ruins", Vec2f(0.0f, 16.0f));
	AddIconToken("$change_class$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 12, 2);

	AddIconToken("$ballistics_calc$", "BallisticsCalculator.png", Vec2f(16, 8), 0);
	AddIconToken("$nav_comp$", "NavComp.png", Vec2f(16, 8), 0);
	AddIconToken("$targeting_unit$", "TargetingUnit.png", Vec2f(16, 16), 0);

	/* TODO ordinance icons
	AddIconToken("$nav_comp$", "NavComp.png", Vec2f(16, 8), 0);
	AddIconToken("$nav_comp$", "NavComp.png", Vec2f(16, 8), 0);
	AddIconToken("$nav_comp$", "NavComp.png", Vec2f(16, 8), 0);
	AddIconToken("$nav_comp$", "NavComp.png", Vec2f(16, 8), 0);
	*/

	AddIconToken("$pod_shield$", "PodShield.png", Vec2f(18, 10), 0);
	AddIconToken("$pod_flak$", "FlakTurret.png", Vec2f(20, 8), 0);
	AddIconToken("$pod_gatling$", "GatlingTurret.png", Vec2f(20, 8), 0);
	AddIconToken("$pod_artillery$", "ArtilleryTurret.png", Vec2f(22, 10), 0);
	AddIconToken("$pod_healgun$", "HealgunTurret.png", Vec2f(16, 8), 0);
	AddIconToken("$pod_generator$", "PodGenerator.png", Vec2f(16, 16), 0);

	//TDM classes
	//addPlayerClass(this, "Knight", "$knight_class_icon$", "knight", "Hack and Slash.");
	//addPlayerClass(this, "Archer", "$archer_class_icon$", "archer", "The Ranged Advantage.");
	addPlayerClass(this, "Fighter", "", "fighter", "Hack and Slash.");
	addPlayerClass(this, "Interceptor", "", "interceptor", "The Ranged Advantage.");
	addPlayerClass(this, "Bomber", "", "bomber", "The Ranged Advantage.");
	addPlayerClass(this, "Scout", "", "scout", "The Ranged Advantage.");
	//addPlayerClass(this, "Martyr", "", "martyr", "The Ranged Advantage.");
	this.getShape().SetStatic(true);
	this.getShape().getConsts().mapCollisions = false;
	this.addCommandID("class menu");

	this.Tag("change class drop inventory");

	this.Tag(bigTag);

	this.getSprite().SetZ(-50.0f);   // push to background
}

void onTick(CBlob@ this)
{
	if (enable_quickswap)
	{
		//quick switch class
		CBlob@ blob = getLocalPlayerBlob();
		if (blob !is null && blob.isMyPlayer())
		{
			if (
				isInRadius(this, blob) && //blob close enough to ruins
				blob.isKeyJustReleased(key_use) && //just released e
				isTap(blob, 7) && //tapped e
				blob.getTickSinceCreated() > 1 //prevents infinite loop of swapping class
			) {
				CycleClass(this, blob);
			}
		}
	}

	CMap@ map = getMap(); //standard map check
	if (map is null)
	{ return; }

	Vec2f thisPos = this.getPosition();
	f32 radius = 128.0f;
	u32 gameTime = getGameTime();
	int teamNum = this.getTeamNum();
	
	if (isServer() && gameTime < 90) //for the first 3 seconds, server only
	{ 
		spawnAttachments(this);
	}

	if (isServer() && gameTime % 30 == 0)
	{
		s32 chargeAmount = 10.0f;

		CBlob@[] blobsInRadius;
		map.getBlobsInRadius(thisPos, radius, @blobsInRadius); //tent aura push
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob@ b = blobsInRadius[i];
			if (b is null)
			{ continue; }

			if (b.getTeamNum() != teamNum)
			{ continue; }

			if (!b.hasTag(chargeTag) || b.hasTag("dead") || b.hasTag(bigTag))
			{ continue; }

			transferCharge(this, b, chargeAmount);
			//addCharge(b, chargeAmount);
		}

		CBlob@[] nonPlayerInRadius;
		map.getBlobsInRadius(thisPos, radius, @nonPlayerInRadius); //tent aura push
		for (uint i = 0; i < nonPlayerInRadius.length; i++)
		{
			CBlob@ b = nonPlayerInRadius[i];
			if (b is null)
			{ continue; }

			if (b.getTeamNum() != teamNum)
			{ continue; }

			if (b.hasTag(bigTag) || !b.hasTag("hull") || b.getPlayer() != null)
			{ continue; }

			Vec2f bPos = b.getPosition();
			Vec2f bVec = bPos - thisPos;
			Vec2f bVecNorm = bVec;
			bVecNorm.Normalize();

			b.setVelocity(b.getVelocity() + (bVecNorm*0.1f));
		}
	}

	if (!isClient())
	{ return; }

	CBlob@[] blobsInRadius;
	map.getBlobsInRadius(thisPos, radius, @blobsInRadius); //tent aura push
	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		CBlob@ b = blobsInRadius[i];
		if (b is null)
		{ continue; }

		if (b.getTeamNum() != teamNum)
		{ continue; }

		if (!b.hasTag(chargeTag) || b.hasTag("dead") || b.hasTag(bigTag))
		{ continue; }

		Vec2f blobPos = b.getPosition();

		makeEnergyLink(thisPos, blobPos, teamNum);
	} //for loop end
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (this == null)
	{ return; }

	if (cmd == this.getCommandID("class menu"))
	{
		u16 callerID;
		if (!params.saferead_u16(callerID)) return;

		CBlob@ caller = getBlobByNetworkID(callerID);

		if (caller !is null && caller.isMyPlayer())
		{
			BuildRespawnMenuFor(this, caller);
		}
	}
	else
	{
		onRespawnCommand(this, cmd, params);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	AddIconToken("$knight_class_icon$", "GUI/MenuItems.png", Vec2f(32, 32), 12, caller.getTeamNum());
	AddIconToken("$archer_class_icon$", "GUI/MenuItems.png", Vec2f(32, 32), 16, caller.getTeamNum());
	
	if (!canSeeButtons(this, caller)) return;

	if (canChangeClass(this, caller))
	{
		if (isInRadius(this, caller))
		{
			BuildRespawnMenuFor(this, caller);
		}
		else
		{
			CBitStream params;
			params.write_u16(caller.getNetworkID());
			caller.CreateGenericButton("$change_class$", Vec2f(0, 6), this, this.getCommandID("class menu"), getTranslatedString("Change class"), params);
		}
	}

	// warning: if we don't have this button just spawn menu here we run into that infinite menus game freeze bug
}

bool isInRadius(CBlob@ this, CBlob @caller)
{
	return (this.getPosition() - caller.getPosition()).Length() < this.getRadius();
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

void spawnAttachments(CBlob@ ownerBlob)
{
	if (ownerBlob == null)
	{ return; }

	CAttachment@ attachments = ownerBlob.getAttachments();
	if (attachments == null)
	{ return; }

	Vec2f ownerPos = ownerBlob.getPosition();
	int teamNum = ownerBlob.getTeamNum();

	AttachmentPoint@ wingNW = attachments.getAttachmentPointByName("WINGNW");
	AttachmentPoint@ wingNE = attachments.getAttachmentPointByName("WINGNE");
	AttachmentPoint@ wingSE = attachments.getAttachmentPointByName("WINGSE");
	AttachmentPoint@ wingSW = attachments.getAttachmentPointByName("WINGSW");

	if (wingNW != null)
	{
		Vec2f slotOffset = wingNW.offset;
		CBlob@ slotBlob = wingNW.getOccupied();
		if (slotBlob == null)
		{
			CBlob@ blob = server_CreateBlob( "station_wing_nw" , teamNum, ownerPos + slotOffset);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				ownerBlob.server_AttachTo(blob, wingNW);
				blob.set_u32("ownerBlobID", ownerBlob.getNetworkID());
				
			}
		}
	}

	if (wingNE != null)
	{
		Vec2f slotOffset = wingNE.offset;
		CBlob@ slotBlob = wingNE.getOccupied();
		if (slotBlob == null)
		{
			CBlob@ blob = server_CreateBlob( "station_wing_ne" , teamNum, ownerPos + slotOffset);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				ownerBlob.server_AttachTo(blob, wingNE);
				blob.set_u32("ownerBlobID", ownerBlob.getNetworkID());
				blob.SetFacingLeft(false);
			}
		}
	}

	if (wingSE != null)
	{
		Vec2f slotOffset = wingSE.offset;
		CBlob@ slotBlob = wingSE.getOccupied();
		if (slotBlob == null)
		{
			CBlob@ blob = server_CreateBlob( "station_wing_se" , teamNum, ownerPos + slotOffset);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				ownerBlob.server_AttachTo(blob, wingSE);
				blob.set_u32("ownerBlobID", ownerBlob.getNetworkID());
				blob.SetFacingLeft(false);
			}
		}
	}

	if (wingSW != null)
	{
		Vec2f slotOffset = wingSW.offset;
		CBlob@ slotBlob = wingSW.getOccupied();
		if (slotBlob == null)
		{
			CBlob@ blob = server_CreateBlob( "station_wing_sw" , teamNum, ownerPos + slotOffset);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				ownerBlob.server_AttachTo(blob, wingSW);
				blob.set_u32("ownerBlobID", ownerBlob.getNetworkID());
			}
		}
	}
	
}