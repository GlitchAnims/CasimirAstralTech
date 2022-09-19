#include "SpaceshipGlobal.as"
#include "ChargeCommon.as"
#include "SmallshipCommon.as"
#include "MediumshipCommon.as"
#include "ComputerCommon.as"
#include "OrdinanceCommon.as"
#include "CommonFX.as"

#include "NavComp.as"
#include "BallisticsCalculator.as"

void onInit(CBlob@ this)
{
	//setup all calcs to false
	this.set_bool(hasNavCompString, false);
	this.set_bool(hasBallisticsString, false);
	this.set_bool(hasTargetingString, false);

	if (this.isMyPlayer())
	{
		this.set_u32(targetingTimerString, 0);
		this.set_u16(currentTargetIDString, 0);
		this.set_f32(interferenceMultString, 0.0f);
	}
	/*
	ComputerTargetInfo compInfo;
	compInfo.current_pos = Vec2f_zero; //this tick position
	compInfo.last_pos = Vec2f_zero; //last tick position
	compInfo.current_vel = Vec2f_zero; //this tick velocity
	compInfo.last_vel = Vec2f_zero; //last tick velocity

	BallisticsOwnerInfo ownerInfo;
	ownerInfo.tickInfo.resize(999999);
	ownerInfo.tickInfo.insertAt(10, compInfo);
	this.set("ownerInfo", ownerInfo);
	*/

}

void onTick(CBlob@ this)
{
	u32 gameTime = getGameTime();
	u32 ticksASecond = getTicksASecond();
	u16 thisNetID = this.getNetworkID();

	const bool my_player = this.isMyPlayer();
	
	if ( (gameTime+thisNetID) % 30 == 0)
	{
		updateInventoryCPU( this );
	}

	if (!my_player && !isServer()) //only server and player
	{ return; }

	if (this.get_s32(absoluteCharge_string) <= 0) //no charge? fucked.
	{ return; }

	const bool hasNavComp = this.get_bool(hasNavCompString);
	const bool hasBallistics = this.get_bool(hasBallisticsString);
	const bool hasTargeting = this.get_bool(hasTargetingString);
	const f32 interference = this.get_f32(interferenceMultString);

	if (!hasNavComp && !hasBallistics && !hasTargeting)
	{ return; }

	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	int teamNum = this.getTeamNum();
	f32 blobAngle = this.getAngleDegrees();
	if (this.hasTag(mediumTag)) blobAngle+=270.0f;
	blobAngle = Maths::Abs(blobAngle) % 360;
	Vec2f aimPos = this.getAimPos();

	if (interference > 0)
	{
		//position interference
		f32 xInterference = 1.0f - (2.0f * _computer_logic_r.NextFloat());
		f32 yInterference =	1.0f - (2.0f * _computer_logic_r.NextFloat());
		Vec2f posInterference = Vec2f(xInterference * maxPosInterference, yInterference * maxPosInterference) * interference;
		//velocity vector interference
		xInterference = 1.0f - (2.0f * _computer_logic_r.NextFloat());
		yInterference =	1.0f - (2.0f * _computer_logic_r.NextFloat());
		Vec2f velInterference = Vec2f(xInterference * maxVelInterference, yInterference * maxVelInterference) * interference;
		//angle interference
		f32 angleInterference = 1.0f - (2.0f * _computer_logic_r.NextFloat());
		//aimpos interference
		xInterference = 1.0f - (2.0f * _computer_logic_r.NextFloat());
		yInterference =	1.0f - (2.0f * _computer_logic_r.NextFloat());
		Vec2f aimInterference = Vec2f(xInterference * maxAimPosInterference, yInterference * maxAimPosInterference) * interference;
		
		thisPos += posInterference;
		thisVel += velInterference;
		blobAngle += angleInterference * maxAngleInterference * interference;
		aimPos += aimInterference;

		this.set_f32(interferenceMultString, interference - 0.005f);
	}

	ComputerBlobInfo ownerInfo;
	ownerInfo.current_pos = thisPos;
	ownerInfo.current_vel = thisVel;
	ownerInfo.team_num = teamNum;
	ownerInfo.blob_angle = blobAngle;
	ownerInfo.interference_mult = interference;
	ownerInfo.current_aimpos = aimPos;

	if (hasNavComp)
	{
		runNavigation( this, gameTime, ticksASecond, thisNetID, ownerInfo );
	}
	if (hasBallistics)
	{
		runBallistics( this, gameTime, ticksASecond, thisNetID, ownerInfo );
	}
	if (hasTargeting)
	{
		runTargeting( this, gameTime, ticksASecond, thisNetID, ownerInfo );
	}

	if (!my_player) //if not my player, do not do the calcs - CUTOFF POINT
	{ return; }

//	if (hasNavComp && !hasBallistics) //ballistics overrides with a different aim line system
//	{
		Vec2f aimVec = Vec2f(300.0f, 0);
		aimVec.RotateByDegrees(blobAngle); //aim vector
		drawParticleLine( thisPos, aimVec + thisPos, Vec2f_zero, greenConsoleColor, 0, 15.0f); //ship aim line
//	}
	

	/*ComputerTargetInfo compInfo;
	compInfo.current_pos = ownerBlob.getPosition(); //this tick position
	compInfo.last_pos = ownerBlob.getOldPosition(); //last tick position
	compInfo.current_vel = ownerBlob.getVelocity(); //this tick velocity
	compInfo.last_vel = ownerBlob.getOldVelocity(); //last tick velocity

	
	u8 gameTimeCast = gameTime;
	u8 varID = gameTimeCast + pingTicks;
	string varName = "ownerInfo" + varID;
	this.set(varName, compInfo);

	if (!this.get( "ownerInfo"+gameTimeCast, @compInfo )) 
	{ return; }*/
	
	/*
	BallisticsOwnerInfo@ ownerInfo;
	if (!this.get( "ownerInfo", @ownerInfo )) 
	{ return; }
	ComputerTargetInfo compInfo; //gets info for this tick
	//compInfo = ownerInfo.tickInfo[gameTime];
	compInfo = ownerInfo.tickInfo.opIndex(gameTime);
	if (compInfo == null)
	{ return; }
	Vec2f ownerPos = compInfo.current_pos;
	Vec2f ownerVel = compInfo.current_vel;

	compInfo.current_pos = ownerBlob.getPosition(); //this tick position
	compInfo.last_pos = ownerBlob.getOldPosition(); //last tick position
	compInfo.current_vel = ownerBlob.getVelocity(); //this tick velocity
	compInfo.last_vel = ownerBlob.getOldVelocity(); //last tick velocity
	
	ownerInfo.tickInfo.insertAt(gameTime + playerPing, compInfo);
	this.set("ownerInfo", ownerInfo);*/
	
}

void runNavigation( CBlob@ ownerBlob, u32 gameTime, u32 ticksASecond, u16 thisNetID, ComputerBlobInfo@ ownerInfo )
{
	if (!ownerBlob.isMyPlayer()) //if not my player, do not do the calcs - CUTOFF POINT
	{ return; }

	const f32 interference = ownerInfo.interference_mult;
	const int teamNum = ownerInfo.team_num;

	CBlob@[] hulls;
	getBlobsByTag("hull", @hulls);
	for(uint i = 0; i < hulls.length(); i++)
	{
		CBlob@ b = hulls[i];
		if (b == null)
		{ continue; }

		f32 targetDist = b.getDistanceTo(ownerBlob);
		if (targetDist > 512) //too far away, don't continue rendering
		{ continue; }

		SColor color = greenConsoleColor;
		if (b.getTeamNum() != teamNum)
		{ 
			color = yellowConsoleColor; //yellow for enemies
		}

		if (b.hasTag(smallTag))
		{
			smallshipNavigation( b, ticksASecond, b is ownerBlob, color, interference );
		}
		else if (b.hasTag(mediumTag))
		{
			mediumshipNavigation( b, ticksASecond, b is ownerBlob, color, interference );
		}
	}
}


void runBallistics( CBlob@ ownerBlob, u32 gameTime, u32 ticksASecond, u16 thisNetID, ComputerBlobInfo@ ownerInfo )
{
	if (isServer() && (gameTime+thisNetID) % 45 == 0) //remove charge one every 1.5 seconds
	{
		removeCharge(ownerBlob, 1, true);
	}

	if (!ownerBlob.isMyPlayer()) //if not my player, do not do the calcs - CUTOFF POINT
	{ return; }

	string ownerBlobName = ownerBlob.getName();
	switch (ownerBlobName.getHash())
	{
		case 0:
		break;
		case 1:
		break;
		case 2:
		break;

		default:
		{
			fighterBallistics( ownerBlob, ownerInfo, ticksASecond );
		}
	}
}


void runTargeting( CBlob@ ownerBlob, u32 gameTime, u32 ticksASecond, u16 thisNetID, ComputerBlobInfo@ ownerInfo )
{
	LauncherInfo@ launcher;
	if (!ownerBlob.get("launcherInfo", @launcher))
	{ return; }
	
	if (isServer() && (gameTime+thisNetID) % 30 == 0) //remove charge one every 1.0 seconds
	{
		removeCharge(ownerBlob, 1, true);
	}

	if (!ownerBlob.isMyPlayer()) //if not my player, do not do the calcs - CUTOFF POINT
	{ return; }

	CMap@ map = getMap(); //standard map check
	if (map is null)
	{ return; }

	const bool isSearching = ownerBlob.isKeyPressed(key_taunts);
	u8 type = launcher.ordinance_type; // currently selected ordinance

	u16 currentTargetNetID = ownerBlob.get_u16(currentTargetIDString);
	if (!isSearching)
	{
		if (launcher.found_targets_id.length > 0)
		{
			launcher.found_targets_id.clear();
		}
		if (currentTargetNetID != 0)
		{
			ownerBlob.set_u16(currentTargetIDString, 0);
		}
		return;
	}

	if (ownerBlob.isKeyPressed(key_action2)) //can't fire and search at the same time
	{ return; }

	Vec2f ownerPos = ownerInfo.current_pos;
	Vec2f ownerVel = ownerInfo.current_vel;
	int teamNum = ownerInfo.team_num;
	f32 ownerAngle = ownerInfo.blob_angle;
	const f32 interference = ownerInfo.interference_mult;
	Vec2f ownerAimpos = ownerInfo.current_aimpos;

	if (!ownerBlob.hasTag(smallTag)) //ignores ship's angle if not a smallship
	{
		Vec2f aimVec = ownerAimpos - ownerPos;
		ownerAngle = -aimVec.getAngleDegrees();
	}

	HitInfo@[] hitInfos;
	
	switch (type)
	{
		case OrdinanceType::aa: //medium cone of target acquisition
		{
			const f32 arcDegrees = 70.0f;
			const f32 range = 600.0f;

			CBlob@[] blobsInRadius;
			map.getBlobsInRadius(ownerPos, range, @blobsInRadius); //possible enemies in radius
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob@ b = blobsInRadius[i];
				if (b is null)
				{ continue; }

				if (b.getTeamNum() == teamNum) //enemy only
				{ continue; }

				if (!b.hasTag(smallTag) && !b.hasTag(mediumTag)) //mediumship and smallship only
				{ continue; }

				Vec2f targetPos = b.getPosition();
				Vec2f targetVec = targetPos - ownerPos;
				f32 targetAngle = -targetVec.getAngleDegrees();

				f32 angleDiff = Maths::Abs(targetAngle - ownerAngle);
				angleDiff = (angleDiff + 180) % 360 - 180;

				if (angleDiff < -arcDegrees/2 || angleDiff > arcDegrees/2)
				{ continue; }

				u16 bNetID = b.getNetworkID();
				int index = launcher.found_targets_id.find(bNetID);
				if (index >= 0 && index < launcher.found_targets_id.length) //skip if ID already in array
				{ continue; }

				if (_computer_logic_r.NextFloat() > 0.025f) //chance to pickup target
				{
					makeTargetSquare(targetPos, 45.0f, Vec2f(8.0f, 8.0f), 4.0f, 4.0f); //target detected rhombus
					continue;
				}

				launcher.found_targets_id.push_back(bNetID); //place ID in array
			}

			//draw detection cone
			Vec2f line1 = Vec2f(range, 0);
			Vec2f line2 = Vec2f(range, 0);
			line1.RotateByDegrees(ownerAngle + (arcDegrees/2));
			line2.RotateByDegrees(ownerAngle - (arcDegrees/2));
			drawParticleLine( ownerPos, line1 + ownerPos, Vec2f_zero, greenConsoleColor, 0, 4.0f);
			drawParticleLine( ownerPos, line2 + ownerPos, Vec2f_zero, greenConsoleColor, 0, 4.0f);
		}
		break;

		case OrdinanceType::cruise:
//		{
			//TODO global target spotting
//		}
//		break;

		case OrdinanceType::emp: //cursor radius acquisition
		{
			const f32 range = 64.0f;

			u16[] validBlobIDs; //detectable enemies go here
			CBlob@[] blobsInRadius;
			map.getBlobsInRadius(ownerAimpos, range, @blobsInRadius); //possible enemies in radius
			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob@ b = blobsInRadius[i];
				if (b is null)
				{ continue; }

				if (b.getTeamNum() == teamNum) //enemy only
				{ continue; }

				if (!b.hasTag(smallTag) && !b.hasTag(mediumTag)) //mediumship and smallship only
				{ continue; }

				u16 bNetID = b.getNetworkID();
				int index = launcher.found_targets_id.find(bNetID);
				if (index >= 0 && index < launcher.found_targets_id.length) //skip if ID already in array
				{ continue; }

				validBlobIDs.push_back(bNetID); //to the pile
			}

			//get closest to mouse
			f32 bestDist = 99999.0f;
			u16 bestBlobNetID = 0;
			for (uint i = 0; i < validBlobIDs.length; i++)
			{
				u16 validNetID = validBlobIDs[i];
				CBlob@ b = getBlobByNetworkID(validNetID);
				if (b is null)
				{ continue; }

				Vec2f targetPos = b.getPosition();
				Vec2f targetVec = targetPos - ownerAimpos;
				f32 targetDist = targetVec.getLength();

				if (targetDist < bestDist)
				{
					bestDist = targetDist;
					bestBlobNetID = validNetID;
				}
			}

			if (bestBlobNetID != 0) //start locking onto valid target
			{
				u32 timer = ownerBlob.get_u32(targetingTimerString);

				CBlob@ bestBlob = getBlobByNetworkID(bestBlobNetID);
				if (bestBlob != null)
				{
					Vec2f targetPos = bestBlob.getPosition();

					if (bestBlobNetID != currentTargetNetID)
					{
						ownerBlob.set_u16(currentTargetIDString, bestBlobNetID);
						timer = 0;
					}
					
					const u32 acquisitionTime = 30;
					if (timer >= acquisitionTime)
					{
						launcher.found_targets_id.push_back(bestBlobNetID); //place ID in array
					}
					else
					{
						f32 percentage = Maths::Clamp(float(timer)/float(acquisitionTime), 0.0f, 1.0f);

						f32 squareAngle = 45.0f * (1.0f-percentage);
						Vec2f squareScale = Vec2f(8.0f, 8.0f)*percentage;
						f32 squareCornerSeparation = 4.0f * percentage;
						makeTargetSquare(targetPos, squareAngle, squareScale, squareCornerSeparation, 1.0f); //target detected rhombus
						print ("loadingBlob: "+ bestBlobNetID);
						print ("timer: "+ timer);
						ownerBlob.set_u32(targetingTimerString, timer+1);
					}
				}
			}
			else //resets if no valid targets in range
			{
				if (currentTargetNetID != 0)
				{
					ownerBlob.set_u16(currentTargetIDString, 0);
				}
			}
			
			//draw detection circle
			drawParticleCircle(ownerAimpos, range, Vec2f_zero, greenConsoleColor, 0, 4.0f);
		}
		break;

		case OrdinanceType::flare:
		break;

		default: return;
	}
	
	//draw square for all saved targets
	for (uint i = 0; i < launcher.found_targets_id.length; i++)
	{
		u16 netID = launcher.found_targets_id[i];
		CBlob@ targetBlob = getBlobByNetworkID(netID);
		if (targetBlob == null)
		{ continue; }

		Vec2f targetPos = targetBlob.getPosition();

		makeTargetSquare(targetPos, 0.0f, Vec2f(8.0f, 8.0f), 4.0f, 1.0f); //target acquired square
	}
}

void updateInventoryCPU( CBlob@ this )
{
	CInventory@ inv = this.getInventory();
	if (inv == null)
	{ return; }

	this.set_bool(hasNavCompString, inv.isInInventory("nav_comp", 1));
	this.set_bool(hasBallisticsString, inv.isInInventory("ballistics_calc", 1));
	this.set_bool(hasTargetingString, inv.isInInventory("targeting_unit", 1));
}