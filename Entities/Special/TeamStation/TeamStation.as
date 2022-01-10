// TDM Ruins logic

#include "ClassSelectMenu.as"
#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "RespawnCommandCommon.as"
#include "GenericButtonCommon.as"
#include "ChargeCommon.as"
#include "CommonFX.as"

Random _TDM_ruins_r(67656);

void onInit(CBlob@ this)
{
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
	f32 radius = 64.0f;
	u32 gameTime = getGameTime();
	int teamNum = this.getTeamNum();

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

			if (!b.hasTag(chargeTag) || b.hasTag("dead"))
			{ continue; }

			addCharge(b, chargeAmount);
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

		if (!b.hasTag(chargeTag) || b.hasTag("dead"))
		{ continue; }

		Vec2f blobPos = b.getPosition();

		makeEnergyLink(thisPos, blobPos, teamNum);
	} //for loop end
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("class menu"))
	{
		u16 callerID = params.read_u16();
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
