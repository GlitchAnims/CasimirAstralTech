// Fighter logic

#include "SpaceshipGlobal.as"
#include "ChargeCommon.as"
#include "SmallshipCommon.as"
#include "SpaceshipVars.as"
#include "HoverMessage.as"
#include "KnockedCommon.as"
#include "OrdinanceCommon.as"
#include "CommonFX.as"
#include "AllHashCodes.as";

const string fire_ordinance_command_ID = "ordinance_shoot";
const string pick_ordinance_command_ID = "pick_ordinance";

Random _launcher_logic_r(19935);
void onInit( CBlob@ this )
{
	//set launcher allowed ordinance types
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

	this.addCommandID(fire_ordinance_command_ID);
	this.addCommandID(pick_ordinance_command_ID);
	
	this.Tag("launcher");
}


void onTick( CBlob@ this )
{
	LauncherInfo@ launcher;
	if (!this.get("launcherInfo", @launcher))
	{ return; }

	//are we responsible for this actor?
	bool ismyplayer = this.isMyPlayer();
	bool responsible = ismyplayer;
	if (isServer() && !ismyplayer)
	{
		CPlayer@ p = this.getPlayer();
		if (p !is null)
		{
			responsible = p.isBot();
		}
	}
	//
	CSprite@ sprite = this.getSprite();
	bool hasCurrentOrdinance = launcher.has_ordinance;
	bool has_aa = hasOrdinance(this, OrdinanceType::aa);
	u32 cooldown = launcher.cooldown;
	u32 cooldownCap = launcher.max_cooldown;
	const bool pressed_action2 = this.isKeyPressed(key_action2);

	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	int teamNum = this.getTeamNum();
	f32 blobAngle = this.getAngleDegrees();

	if (cooldown > 0) //tick down cooldown
	{
		launcher.cooldown = cooldown-1;
	}

	if (responsible)
	{
		if ((getGameTime() + this.getNetworkID()) % 10 == 0)
		{
			hasCurrentOrdinance = hasOrdinance(this);

			if (!hasCurrentOrdinance && has_aa)
			{
				// set back to default
				launcher.ordinance_type = OrdinanceType::aa;
				hasCurrentOrdinance = has_aa;
			}
		}

		if (hasCurrentOrdinance != this.get_bool("has_ord"))
		{
			this.set_bool("has_ord", hasCurrentOrdinance);
			this.Sync("has_ord", isServer());
		}
	}
	
	//charged - no else (we want to check the very same tick)
	if (this.isKeyPressed(key_action2))
	{
		const bool just_action2 = this.isKeyJustPressed(key_action2);
		const bool reloaded = cooldown == 0;
		const bool canFire = hasCurrentOrdinance && reloaded;

		//reload circle at mouse pos
		if (!canFire && ismyplayer && cooldownCap != 0)
		{
			f32 reloadPercentage = float(cooldown) / float(cooldownCap);
			Vec2f aimPos = this.getAimPos();
			drawParticlePartialCircle( aimPos, 16.0f, reloadPercentage, 0, greenConsoleColor, 0, 2.0f);
		}

		if (just_action2)
		{
			hasCurrentOrdinance = hasOrdinance(this);

			if (!hasCurrentOrdinance && has_aa) //switch to default ammo if current ammo is empty
			{
				launcher.ordinance_type = OrdinanceType::aa;
				hasCurrentOrdinance = has_aa;
			}

			if (responsible)
			{
				this.set_bool("has_ord", hasCurrentOrdinance);
				this.Sync("has_ord", isServer());
			}

			if (!canFire) // playing annoying no ammo sound
			{
				if (!hasCurrentOrdinance)
				{
					failedLaunchEffect(this, "No ammo");
				}
				else if (!reloaded)
				{
					failedLaunchEffect(this, "Reloading...");
				}
			}
			else //has ammo
			{
				if (ismyplayer)
				{
					const u8 type = launcher.ordinance_type;
					u32 addedCooldown = getOrdinanceCooldown(type);

					u8 ammoCount = this.getBlobCount(ordinanceTypeNames[type]);
					if (ammoCount <= 0)
					{
						failedLaunchEffect(this, "No ammo");
						return;
					}

					int targetAmount = launcher.found_targets_id.length;
					bool noTarget = targetAmount <= 0;

					OrdinanceLaunchInfo[] launches;

					OrdinanceLaunchInfo launchInfo;
					launchInfo.ordinance = type;
					
					switch (type)
					{
						case OrdinanceType::aa:
						{
							bool leftCannon = this.get_bool( "leftCannonTurn" );
							if (noTarget)
							{
								this.set_bool( "leftCannonTurn", !leftCannon);
								f32 leftMult = leftCannon ? 1.0f : -1.0f;

								Vec2f launchpos = Vec2f(0, 8.0f*leftMult);
								f32 launchAngle = this.hasTag(smallTag) ? blobAngle : blobAngle+90.0f;
								Vec2f launchVec = Vec2f(0, 1.0f*leftMult).RotateByDegrees(launchAngle);
								launchInfo.launch_pos 	= launchpos+thisPos;
								launchInfo.launch_vec 	= launchVec+thisVel;

								launches.push_back(launchInfo);
							}
							else
							{
								u32 tempCooldown = addedCooldown;
								for (uint i = 0; i < targetAmount; i++)
								{
									if (ammoCount <= 0) //stop if no ammo left
									{ break; }
									leftCannon = !leftCannon;
									f32 leftMult = leftCannon ? 1.0f : -1.0f;

									u16 targetID = launcher.found_targets_id[i];
									Vec2f launchpos = Vec2f(0, 8.0f*leftMult);
									f32 launchAngle = this.hasTag(smallTag) ? blobAngle : blobAngle+90.0f;
									Vec2f launchVec = Vec2f(0, 1.0f*leftMult).RotateByDegrees(launchAngle);
									launchInfo.target_ID 	= targetID;
									launchInfo.launch_pos 	= launchpos+thisPos;
									launchInfo.launch_vec 	= launchVec+thisVel;
									
									ammoCount--;
									addedCooldown += tempCooldown;
									launches.push_back(launchInfo);

									//duplicate code, for now
									if (ammoCount <= 0) //stop if no ammo left
									{ break; }
									leftCannon = !leftCannon;
									leftMult = leftCannon ? 1.0f : -1.0f;

									//targetID = launcher.found_targets_id[i];
									launchpos = Vec2f(0, 8.0f*leftMult);
									//launchAngle = this.hasTag(smallTag) ? blobAngle : blobAngle+90.0f;
									launchVec = Vec2f(0, 1.0f*leftMult).RotateByDegrees(launchAngle);
									launchInfo.target_ID 	= targetID;
									launchInfo.launch_pos 	= launchpos+thisPos;
									launchInfo.launch_vec 	= launchVec+thisVel;
									
									ammoCount--;
									addedCooldown += tempCooldown;
									launches.push_back(launchInfo);
								}
								
								this.set_bool( "leftCannonTurn", !leftCannon);
							}
						}
						break;

						case OrdinanceType::cruise:
						{
							if (noTarget)
							{
								failedLaunchEffect(this, "Cruise missile requires target");
								return;
							}

							u16 targetID = launcher.found_targets_id[0];
							f32 launchAngle = this.hasTag(smallTag) ? blobAngle : blobAngle+90.0f;
							Vec2f launchVec = Vec2f(1.0f, 0).RotateByDegrees(launchAngle);
							launchInfo.target_ID 	= targetID;
							launchInfo.launch_pos 	= thisPos;
							launchInfo.launch_vec 	= launchVec+thisVel;

							launches.push_back(launchInfo);
						}
						break;

						case OrdinanceType::emp: 
						{

						}
						break;

						case OrdinanceType::flare:
						{
							
						}
						break;

						default: return;
					}

					if (launches.length > 0)
					{
						ShootOrdinance( this, launches );
						launcher.max_cooldown = addedCooldown; //for reload circle logic
						launcher.cooldown = addedCooldown; //add cumulative cooldown
						launcher.found_targets_id.clear(); //clear list, already fired
					}
				}
			}
		}
	}

	launcher.has_ordinance = hasCurrentOrdinance;
}

bool canSend(CBlob@ this)
{
	return (this.isMyPlayer() || this.getPlayer() is null || this.getPlayer().isBot());
}

void ShootOrdinance(CBlob @this, OrdinanceLaunchInfo[] launches )
{
	if (canSend(this)) // player or bot
	{
		CBitStream params;
		for (uint i = 0; i < launches.length; i++) //write a set for each target
		{
			OrdinanceLaunchInfo launchInfo = launches[i];

			u8 ordinanceType = launchInfo.ordinance;
			u16 targetID = launchInfo.target_ID;
			Vec2f launchPos = launchInfo.launch_pos;
			Vec2f launchVec = launchInfo.launch_vec;

			params.write_u8(ordinanceType);
			params.write_u16(targetID);
			params.write_Vec2f(launchPos);
			params.write_Vec2f(launchVec);
		}
		this.getSprite().PlaySound("Entities/Characters/Archer/BowFire.ogg");
		this.SendCommand(this.getCommandID(fire_ordinance_command_ID), params);
	}
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

			CBitStream params;
			params.write_u8(currentOrdinance);
			CGridButton @button = menu.AddButton(ordinanceIcons[currentOrdinance], getTranslatedString(ordinanceNames[currentOrdinance]), this.getCommandID(pick_ordinance_command_ID), params);

			if (button !is null)
			{
				bool enabled = hasOrdinance(this, currentOrdinance);
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

CBlob@ CreateOrdinance( CBlob@ this, u8 ordinanceType, u16 targetID, Vec2f blobPos, Vec2f blobVel )
{
	//Vec2f thisPos = this.getPosition();
	//Vec2f thisVel = this.getVelocity();

	CBlob@ newOrd = server_CreateBlob(ordinanceBlobNames[ ordinanceType ], this.getTeamNum(), blobPos);
	if (newOrd !is null)
	{
		newOrd.SetDamageOwnerPlayer(this.getPlayer());
		newOrd.IgnoreCollisionWhileOverlapped( this );
		newOrd.setVelocity( blobVel );
		newOrd.set_f32(shotLifetimeString, 30.0f); //a full second for now
		newOrd.set_u16(targetNetIDString, targetID);
	}
	return newOrd;
}

void CycleToOrdinanceType(CBlob@ this, LauncherInfo@ launcher, u8 ordinanceType)
{
	launcher.found_targets_id.clear();
	launcher.ordinance_type = ordinanceType;
	if (this.isMyPlayer())
	{
		Sound::Play("/CycleInventory.ogg");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID(fire_ordinance_command_ID))
	{
		u8 ordinanceType;
		u16 targetID;
		Vec2f blobPos;
		Vec2f blobVel;

		u8 consumedAmmo = 0;

		while (params.saferead_u8(ordinanceType) && params.saferead_u16(targetID) && params.saferead_Vec2f(blobPos) && params.saferead_Vec2f(blobVel)) //immediately stops if something fails
		{
			if (blobPos == Vec2f_zero || blobVel == Vec2f_zero)
			{ continue; }

			if (ordinanceType >= ordinanceTypeNames.length) 
			{ continue; }

			if (!hasOrdinance(this, ordinanceType))
			{ return; } // return to normal ordinance - server didnt have this synced

			if (isServer())
			{
				CreateOrdinance(this, ordinanceType, targetID, blobPos, blobVel);
			}
			consumedAmmo++;
		}

		if (consumedAmmo > 0)
		{
			this.TakeBlob(ordinanceTypeNames[ ordinanceType ], consumedAmmo);
		}
	}
	else if (cmd == this.getCommandID("cycle"))  //from standardcontrols
	{
		// cycle ordinance
		LauncherInfo@ launcher;
		if (!this.get("launcherInfo", @launcher))
		{ return; }

		u8 type = launcher.ordinance_type;

		int count = 0;
		while (count < ordinanceTypeNames.length)
		{
			type++;
			count++;
			if (type >= ordinanceTypeNames.length)
			{
				type = 0;
			}
			if (hasOrdinance(this, type))
			{
				CycleToOrdinanceType(this, launcher, type);
				break;
			}
		}
	}
	else if (cmd == this.getCommandID("switch") || cmd == this.getCommandID(pick_ordinance_command_ID))
	{
		// switch to ordinance
		LauncherInfo@ launcher;
		if (!this.get("launcherInfo", @launcher))
		{ return; }

		u8 type;
		if (params.saferead_u8(type) && hasOrdinance(this, type))
		{
			CycleToOrdinanceType(this, launcher, type);
		}
	}
}

void failedLaunchEffect( CBlob@ blob, string msg )
{
	if (!blob.isMyPlayer())
	{ return; }

	blob.getSprite().PlaySound("Entities/Characters/Sounds/NoAmmo.ogg", 0.5);

	if (msg.length() <= 0)
	{ return; }

	ShipWarningMessage@ message = cast<ShipWarningMessage>(add_message(
				ShipWarningMessage(msg),
				true
			));
}