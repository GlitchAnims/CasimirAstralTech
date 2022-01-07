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
	/*
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
	bool hasarrow = archer.has_arrow;
	bool hasnormal = hasOrdinance(this, ArrowType::normal);
	s8 charge_time = archer.charge_time;
	u8 charge_state = archer.charge_state;
	const bool pressed_action2 = this.isKeyPressed(key_action2);
	Vec2f pos = this.getPosition();

	if (responsible)
	{
		if ((getGameTime() + this.getNetworkID()) % 10 == 0)
		{
			hasarrow = hasOrdinance(this);

			if (!hasarrow && hasnormal)
			{
				// set back to default
				archer.arrow_type = ArrowType::normal;
				hasarrow = hasnormal;
			}
		}

		if (hasarrow != this.get_bool("has_arrow"))
		{
			this.set_bool("has_arrow", hasarrow);
			this.Sync("has_arrow", isServer());
		}

	}

	if (charge_state == ArcherParams::legolas_charging) // fast arrows
	{
		if (!hasarrow)
		{
			charge_state = ArcherParams::not_aiming;
			charge_time = 0;
		}
		else
		{
			charge_state = ArcherParams::legolas_ready;
		}
	}
	
	//charged - no else (we want to check the very same tick)
	if (this.isKeyPressed(key_action1))
	{
		const bool just_action1 = this.isKeyJustPressed(key_action1);

		//	printf("charge_state " + charge_state );

		if ((just_action1 || this.wasKeyPressed(key_action2) && !pressed_action2) &&
		        (charge_state == ArcherParams::not_aiming || charge_state == ArcherParams::fired || charge_state == ArcherParams::stabbing))
		{
			charge_state = ArcherParams::readying;
			hasarrow = hasOrdinance(this);

			if (!hasarrow && hasnormal)
			{
				archer.arrow_type = ArrowType::normal;
				hasarrow = hasnormal;

			}

			if (responsible)
			{
				this.set_bool("has_arrow", hasarrow);
				this.Sync("has_arrow", isServer());
			}

			charge_time = 0;

			if (!hasarrow)
			{
				charge_state = ArcherParams::no_arrows;

				if (ismyplayer && !this.wasKeyPressed(key_action1))   // playing annoying no ammo sound
				{
					this.getSprite().PlaySound("Entities/Characters/Sounds/NoAmmo.ogg", 0.5);
				}

			}
			else
			{
				if (ismyplayer)
				{
					if (just_action1)
					{
						const u8 type = archer.arrow_type;

						if (type == ArrowType::water)
						{
							sprite.PlayRandomSound("/WaterBubble");
						}
						else if (type == ArrowType::fire)
						{
							sprite.PlaySound("SparkleShort.ogg");
						}
					}
				}

				sprite.RewindEmitSound();
				sprite.SetEmitSoundPaused(false);

				if (!ismyplayer)   // lower the volume of other players charging  - ooo good idea
				{
					sprite.SetEmitSoundVolume(0.5f);
				}
			}
		}
		else if (charge_state == ArcherParams::readying)
		{
			charge_time++;

			if (charge_time > ArcherParams::ready_time)
			{
				charge_time = 1;
				charge_state = ArcherParams::charging;
			}
		}
		else if (charge_state == ArcherParams::charging)
		{
			if(!hasarrow)
			{
				charge_state = ArcherParams::no_arrows;
				charge_time = 0;
				
				if (ismyplayer)   // playing annoying no ammo sound
				{
					this.getSprite().PlaySound("Entities/Characters/Sounds/NoAmmo.ogg", 0.5);
				}
			}
			else
			{
				charge_time++;
			}

			if (charge_time >= ArcherParams::legolas_period)
			{
				// Legolas state

				Sound::Play("AnimeSword.ogg", pos, ismyplayer ? 1.3f : 0.7f);
				Sound::Play("FastBowPull.ogg", pos);
				charge_state = ArcherParams::legolas_charging;
				charge_time = ArcherParams::shoot_period - ArcherParams::legolas_charge_time;

				archer.legolas_arrows = ArcherParams::legolas_arrows_count;
				archer.legolas_time = ArcherParams::legolas_time;
			}

			if (charge_time >= ArcherParams::shoot_period)
			{
				sprite.SetEmitSoundPaused(true);
			}
		}
		else if (charge_state == ArcherParams::no_arrows)
		{
			if (charge_time < ArcherParams::ready_time)
			{
				charge_time++;
			}
		}
	}
	else
	{
		if (charge_state > ArcherParams::readying)
		{
			if (charge_state < ArcherParams::fired)
			{
				ClientFire(this, charge_time, hasarrow, archer.arrow_type, false);

				charge_time = ArcherParams::fired_time;
				charge_state = ArcherParams::fired;
			}
			else if(charge_state == ArcherParams::stabbing)
			{
				archer.stab_delay++;
				if (archer.stab_delay == STAB_DELAY)
				{
					// hit tree and get an arrow
					CBlob@ stabTarget = getBlobByNetworkID(this.get_u16("stabHitID"));
					if (stabTarget !is null)
					{
						if (stabTarget.getName() == "mat_wood")
						{
							u16 quantity = stabTarget.getQuantity();
							if (quantity > 4)
							{
								stabTarget.server_SetQuantity(quantity-4);
							}
							else
							{
								stabTarget.server_Die();

							}
							fletchArrow(this);
						}
						else
						{
							this.server_Hit(stabTarget, stabTarget.getPosition(), Vec2f_zero, 0.25f,  Hitters::stab);

						}

					}
				}
				else if(archer.stab_delay >= STAB_TIME)
				{
					charge_state = ArcherParams::not_aiming;
				}
			}
			else //fired..
			{
				charge_time--;

				if (charge_time <= 0)
				{
					charge_state = ArcherParams::not_aiming;
					charge_time = 0;
				}
			}
		}
		else
		{
			charge_state = ArcherParams::not_aiming;    //set to not aiming either way
			charge_time = 0;
		}

		sprite.SetEmitSoundPaused(true);
	}

	// safe disable bomb light

	if (this.wasKeyPressed(key_action1) && !this.isKeyPressed(key_action1))
	{
		const u8 type = archer.arrow_type;
		if (type == ArrowType::bomb)
		{
			BombFuseOff(this);
		}
	}

	// my player!

	if (responsible)
	{
		// set cursor

		if (ismyplayer && !getHUD().hasButtons())
		{
			int frame = 0;
			//	print("archer.charge_time " + archer.charge_time + " / " + ArcherParams::shoot_period );
			if (archer.charge_state == ArcherParams::readying)
			{
				//readying shot
				frame = 2 + int((float(archer.charge_time) / float(ArcherParams::shoot_period + ArcherParams::ready_time)) * 8) * 2.0f;
			}
			else if (archer.charge_state == ArcherParams::charging)
			{
				if (archer.charge_time < ArcherParams::shoot_period)
				{
					//charging shot
					frame = 2 + int((float(ArcherParams::ready_time + archer.charge_time) / float(ArcherParams::shoot_period + ArcherParams::ready_time)) * 8) * 2;
				}
				else
				{
					//charging legolas
					frame = 1 + int((float(archer.charge_time - ArcherParams::shoot_period) / (ArcherParams::legolas_period - ArcherParams::shoot_period)) * 9) * 2;
				}
			}
			else if (archer.charge_state == ArcherParams::legolas_ready)
			{
				//legolas ready
				frame = 19;
			}
			else if (archer.charge_state == ArcherParams::legolas_charging)
			{
				//in between shooting multiple legolas shots
				frame = 1;
			}
			getHUD().SetCursorFrame(frame);
		}

		// activate/throw

		if (this.isKeyJustPressed(key_action3))
		{
			client_SendThrowOrActivateCommand(this);
		}

		// pick up arrow

		if (archer.fletch_cooldown > 0)
		{
			archer.fletch_cooldown--;
		}

		// pickup from ground

		if (archer.fletch_cooldown == 0 && this.isKeyPressed(key_action2))
		{
			if (getPickupArrow(this) !is null)   // pickup arrow from ground
			{
				this.SendCommand(this.getCommandID("pickup arrow"));
				archer.fletch_cooldown = PICKUP_COOLDOWN;
			}
		}
	}

	archer.charge_time = charge_time;
	archer.charge_state = charge_state;
	archer.has_arrow = hasarrow;
	*/
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

CBlob@ CreateOrdinance(CBlob@ this, Vec2f blobPos, Vec2f blobVel, u8 ordinanceType)
{
	Vec2f thisVel = this.getVelocity();

	CBlob@ arrow = server_CreateBlob(ordinanceBlobNames[ ordinanceType ], this.getTeamNum(), blobPos);
	if (arrow !is null)
	{
		arrow.SetDamageOwnerPlayer(this.getPlayer());
		arrow.IgnoreCollisionWhileOverlapped(this);
		arrow.setVelocity(blobVel + thisVel);


	}
	return arrow;
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
		Vec2f blobPos;
		if (!params.saferead_Vec2f(blobPos)) return;
		Vec2f blobVel;
		if (!params.saferead_Vec2f(blobVel)) return;
		u8 ordinanceType;
		if (!params.saferead_u8(ordinanceType)) return;

		u16 targetBlobID = 0;
		u16 tempID = 0;
		if (params.saferead_u16(tempID))
		{
			targetBlobID = tempID; //if a target ID was sent, use it
		}

		if (ordinanceType >= ordinanceTypeNames.length) return;

		LauncherInfo@ launcher;
		if (!this.get("launcherInfo", @launcher))
		{ return; }

		u8 type = launcher.ordinance_type;

		// return to normal ordinance - server didnt have this synced
		if (!hasOrdinance(this, ordinanceType))
		{ return; }

		if (isServer())
		{
			CreateOrdinance(this, blobPos, blobVel, ordinanceType);
		}

		this.getSprite().PlaySound("Entities/Characters/Archer/BowFire.ogg");
		this.TakeBlob(ordinanceTypeNames[ ordinanceType ], 1);
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