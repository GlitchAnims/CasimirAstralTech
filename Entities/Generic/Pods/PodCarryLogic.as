// PodShield logic

#include "SpaceshipGlobal.as"
#include "PodCommon.as"
#include "SpaceshipVars.as"
#include "CommonFX.as"

Random _pod_logic_r(98444);
void onInit( CBlob@ this )
{
	this.set_bool(canCarryBoolString, true);
	this.set_bool(isCarriedBoolString, false);
	this.set_u16(carrierBlobNetidString, 0);
	
	this.Tag("npc");
	this.Tag("hull");

	this.getShape().SetGravityScale(0);
	this.getShape().getConsts().mapCollisions = true;

	//this.getShape().getConsts().net_threshold_multiplier = 0.5f;
	
	this.SetMapEdgeFlags(CBlob::map_collide_up | CBlob::map_collide_down | CBlob::map_collide_sides);
	this.getCurrentScript().removeIfTag = "dead";
	
	AddIconToken("$new_carry$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 0);
	AddIconToken("$stop_carry$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 1);
	AddIconToken("$carry_blocked$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 9);
	this.addCommandID( pod_carry_toggle_ID );
}

void onTick( CBlob@ this )
{
	// vvvvvvvvvvvvvv SERVER-SIDE ONLY vvvvvvvvvvvvvvvvvvv
	if (!isServer()) return;

	PodInfo@ pod;
	if (!this.get( "podInfo", @pod )) 
	{ return; }

	u32 gameTime = getGameTime();

	if (!this.get_bool(isCarriedBoolString))
	{ return; }

	u16 ownerBlobID = this.get_u16(carrierBlobNetidString);
	CBlob@ ownerBlob = getBlobByNetworkID(ownerBlobID);
	if (ownerBlobID != 0 && ownerBlob != null)
	{ 
		Vec2f thisPos = this.getPosition();
		Vec2f thisVel = this.getVelocity();
		f32 blobAngle = this.getAngleDegrees();
		blobAngle = (blobAngle+360.0f) % 360;
		
		Vec2f ownerPos = ownerBlob.getPosition();
		Vec2f ownerAimpos = ownerBlob.getAimPos();
		Vec2f aimVec = ownerAimpos - thisPos;
		Vec2f ownerVec = ownerPos - thisPos;
		Vec2f ownerVecNorm = ownerVec;
		ownerVecNorm.Normalize();
		f32 ownerDist = ownerVec.getLength();
		f32 aimAngle = aimVec.getAngleDegrees();
		aimAngle *= -1.0f;

		float minCarryDist = pod.carry_dist;
		float carrySpeed = pod.carry_vel * (Maths::Clamp(ownerDist - minCarryDist, 0, minCarryDist) * 0.1f);

		if (carrySpeed > 0)
		{
			Vec2f carryVel = ownerVecNorm * carrySpeed;
			this.setVelocity(thisVel + carryVel);
		}
		
		if (pod.carry_can_turn && blobAngle != aimAngle) //aiming logic
		{
			f32 turnSpeed = pod.carry_turn_speed; //turn rate

			f32 angleDiff = blobAngle - aimAngle;
			angleDiff = (angleDiff + 180) % 360 - 180;

			if (turnSpeed <= 0 || (angleDiff < turnSpeed && angleDiff > -turnSpeed)) //if turn difference is smaller than turn speed, snap to it
			{
				this.setAngleDegrees(aimAngle);
			}
			else
			{
				f32 turnAngle = angleDiff > 0 ? -turnSpeed : turnSpeed; //either left or right turn
				this.setAngleDegrees(blobAngle + turnAngle);
				this.setAngleDegrees(blobAngle + turnAngle);
			}
			blobAngle = this.getAngleDegrees();
		}
	}
	else
	{
		this.set_bool(isCarriedBoolString, false);
		this.set_u16(carrierBlobNetidString, 0);
	}

	//sound logic
	/*Vec2f vel = this.getVelocity();
	float posVelX = Maths::Abs(vel.x);
	float posVelY = Maths::Abs(vel.y);
	if(posVelX > 2.9f)
	{
		this.getSprite().SetEmitSoundVolume(3.0f);
	}
	else
	{
		this.getSprite().SetEmitSoundVolume(1.0f * (posVelX > posVelY ? posVelX : posVelY));
	}*/
}



f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    if (( hitterBlob.getName() == "wraith" || hitterBlob.getName() == "orb" ) && hitterBlob.getTeamNum() == this.getTeamNum())
        return 0;

	if (isClient())
	{
		makeHullHitSparks( worldPoint, 15 );
	}

    return damage;
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
	//empty
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.doTickScripts = true;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	bool hasCarrier = true;

	u16 ownerBlobID = this.get_u16(carrierBlobNetidString);
	CBlob@ ownerBlob = getBlobByNetworkID(ownerBlobID);
	if (ownerBlobID == 0 || ownerBlob == null)
	{ 
		hasCarrier = false;
	}

	if (caller.getTeamNum() == this.getTeamNum()) 
	{
		u16 newCarrierNetID = 0;
		
		string buttonIconString = "$new_carry$";
		string buttonDescString = "Start Carrying";
		if(!this.get_bool(canCarryBoolString))
		{
			buttonIconString = "$carry_blocked$";
			buttonDescString = "This pod cannot be carried";
			caller.CreateGenericButton(buttonIconString, Vec2f(0, 0), this, 0, getTranslatedString(buttonDescString));
			return;
		}

		if(hasCarrier && caller is ownerBlob) //disconnect if carrier
		{
			buttonIconString = "$stop_carry$";
			buttonDescString = "Stop Carrying";
		}
		else
		{
			newCarrierNetID = caller.getNetworkID();
		}

		CBitStream params;
		params.write_u16(newCarrierNetID);
		caller.CreateGenericButton(buttonIconString, Vec2f(0, 0), this, this.getCommandID(pod_carry_toggle_ID), getTranslatedString(buttonDescString), params);
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (this == null)
	{ return; }
	
    if (cmd == this.getCommandID(pod_carry_toggle_ID)) // 1 shot instance
    {
		bool hasCarrier = true;
		bool isBeingCarried = this.get_bool(isCarriedBoolString);

		u16 ownerBlobID = this.get_u16(carrierBlobNetidString);
		CBlob@ ownerBlob = getBlobByNetworkID(ownerBlobID);
		if (ownerBlobID == 0 || ownerBlob == null)
		{ 
			hasCarrier = false;
		}

		u16 newCarrierNetID;
		if (!params.saferead_u16(newCarrierNetID)) return;
		
		if (newCarrierNetID == 0)
		{
			this.set_bool(isCarriedBoolString, false);
			this.set_u16(carrierBlobNetidString, 0);
		}
		else
		{
			this.set_bool(isCarriedBoolString, true);
			this.set_u16(carrierBlobNetidString, newCarrierNetID);
		}
	}
}