// Fighter logic

#include "SpaceshipGlobal.as"
#include "ChargeCommon.as"
#include "SmallshipCommon.as"
#include "SpaceshipVars.as"
#include "ThrowCommon.as"
#include "KnockedCommon.as"
#include "OrdinanceCommon.as"
#include "CommonFX.as"
#include "AllHashCodes.as";

Random _launcher_logic_r(19935);
void onInit( CBlob@ this )
{

	LauncherInfo launcher;
	
	int blobHash = this.getName().getHash();
	switch(blobHash)
	{
		case _bomber:
		{
			u8[] ord = {0, 1, 2};
			launcher.launchableOrdinance.opAssign( ord );
		}
		break;

		case _scout:
		{
			u8[] ord = {0, 1};
			launcher.launchableOrdinance.opAssign( ord );
		}
		break;

		case _foul:
		{
			u8[] ord = {0, 1, 2, 3};
			launcher.launchableOrdinance.opAssign( ord );
		}
		break;

		case _wanderer:
		{
			u8[] ord = {0, 3};
			launcher.launchableOrdinance.opAssign( ord );
		}
		break;

		default: break;
	}
	
	this.set("launcherInfo", @launcher);

	
	
	this.Tag("launcher");
}


void onTick( CBlob@ this )
{

}



//missile menu
void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu @gridmenu)
{
	LauncherInfo@ launcher;
	if (!this.get("launcherInfo", @launcher))
	{ return; }

	const u8 allowedOrdinance = launcher.launchableOrdinance.length;
	if (allowedOrdinance == 0)
	{ return; }

	AddIconToken("$MissileAA$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 0, this.getTeamNum());
	AddIconToken("$MissileCruise$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 1, this.getTeamNum());
	AddIconToken("$MissileEMP$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 2, this.getTeamNum());
	AddIconToken("$MissileFlare$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 3, this.getTeamNum());

	this.ClearGridMenusExceptInventory();
	Vec2f pos(gridmenu.getUpperLeftPosition().x + 0.5f * (gridmenu.getLowerRightPosition().x - gridmenu.getUpperLeftPosition().x),
	          gridmenu.getUpperLeftPosition().y - 32 * 1 - 2 * 24);
	CGridMenu@ menu = CreateGridMenu(pos, this, Vec2f(allowedOrdinance, 2), getTranslatedString("Current Ordinance"));

	const u8 arrowSel = launcher.ordinance_type;

	if (menu !is null)
	{
		menu.deleteAfterClick = false;

		for (uint i = 0; i < allowedOrdinance; i++)
		{
			u8 currentOrdinance = launcher.launchableOrdinance[i];
			string matname = ordinanceTypeNames[currentOrdinance];
			CGridButton @button = menu.AddButton(ordinanceIcons[currentOrdinance], getTranslatedString(ordinanceNames[currentOrdinance]), this.getCommandID("pick " + matname));

			if (button !is null)
			{
				bool enabled = hasArrows(this, currentOrdinance);
				button.SetEnabled(enabled);
				button.selectOneOnClick = true;

				if (arrowSel == currentOrdinance)
				{
					button.SetSelected(1);
				}
			}
		}
	}
}