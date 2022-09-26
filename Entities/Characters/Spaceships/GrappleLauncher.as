#include "GrappleCommon.as"

void onInit( CBlob@ this )
{
	this.set_u32( "shift_heldTime", 0 );
	
	GrappleInfo grapple;
	grapple.hookBlobNetID = 0;
	grapple.chainLength = 0.0f;
	grapple.grappledBlobNetID = 0;
	this.set("grappleInfo", @grapple);

	ChainInfo chain;
	this.set("chainInfo", @chain);

	if (isClient())
	{
		this.set_f32( "grapplesound_progress", 0.0f );
	}

	this.addCommandID(launchGrappleCommandID);
	this.addCommandID(grappleSyncCommandID);
}

void onSetPlayer( CBlob@ this, CPlayer@ player )
{
	if (player !is null){
		player.SetScoreboardVars("ScoreboardIcons.png", 2, Vec2f(16,16));
	}
}

void onTick( CBlob@ this )
{
	if (this.isInInventory()) return;

	const u32 gameTimeVariation = getGameTime() + this.getNetworkID();

	GrappleInfo@ grapple; // global
	if (!this.get( "grappleInfo", @grapple )) return;

	ChainInfo@ chain; // client chain effect
    if (!this.get( "chainInfo", @chain )) return;

	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	f32 blobAngle = this.getAngleDegrees();
	blobAngle = (blobAngle+360.0f) % 360;

	bool isGrappleDeployed = false;
	u16 hookBlobNetID = grapple.hookBlobNetID;

	float chainLength = grapple.chainLength;

	CBlob@ hookBlob = getBlobByNetworkID(hookBlobNetID);
	const bool isHookNull = hookBlob == null;
	if (hookBlobNetID == 0 || isHookNull)
	{
		if (isServer())
		{
			if (hookBlobNetID != 0 && isHookNull)
			{
				grappleSync(this);
			}
			else if (hookBlobNetID == 0 && !isHookNull)
			{
				grappleSync(this);
			}
		}
		if (isClient())
		{
			chain.movingLinkList.clear();
			chain.boneList.clear();
		}
	}
	else if (!isHookNull)
	{
		isGrappleDeployed = true;

		u16 grappledBlobNetID = grapple.grappledBlobNetID;

		Vec2f hookPos = hookBlob.getPosition();
		Vec2f hookVec = hookPos - thisPos;
		Vec2f hookVecNorm = hookVec;
		hookVecNorm.Normalize();

		float hookDist = hookVec.getLength();

		if (hookDist > 400.0f)
		{
			hookDist = 400.0f;
			hookPos = (hookVecNorm*hookDist)+thisPos;
			hookVec = hookPos - thisPos;
			hookBlob.setPosition(hookPos - hookVecNorm);
			hookBlob.setVelocity(thisVel + (-hookVecNorm));
		}

		if (hookBlob.get_bool(hookIsAttachedBoolString))
		{
			grappledBlobNetID = hookBlob.get_u16(hookTargetNetIDString);
			grapple.grappledBlobNetID = grappledBlobNetID;
		}
		else 
		{
			grapple.grappledBlobNetID = 0;
			grappledBlobNetID = 0;

			if (chainLength < hookDist)
			{
				chainLength == hookDist;
				grapple.chainLength = hookDist;
			}
		}

		CBlob@ grappledBlob = getBlobByNetworkID(grappledBlobNetID);
		if (grappledBlob != null)
		{
			float thisMass = this.getMass();
			float grappledMass = grappledBlob.getMass();

			float pullDist = Maths::Max(hookDist-chainLength, 0.0f);

			if (pullDist > 0)
			{
				float hookVecAngle = hookVecNorm.getAngleDegrees();
				float thisVelAngle = thisVel.getAngleDegrees();

				float angleDiff = hookVecAngle - thisVelAngle;
				angleDiff += angleDiff > 180 ? -360 : angleDiff < -180 ? 360 : 0;
				angleDiff = Maths::Abs(angleDiff);

				Vec2f hookPullVel;
				if (angleDiff > 90.0f)
				{
					angleDiff -= 90.0f;
					float velAffect = angleDiff/90.0f;
					print ("velAffect: "+ velAffect);
					this.setVelocity(thisVel + (hookVecNorm*pullDist*velAffect));
				}

				this.setPosition(thisPos + (hookVecNorm*pullDist));
				thisPos = this.getPosition();
				grappledBlob.AddForceAtPosition(-hookVecNorm*pullDist*20.0f, hookPos);
			}
		}
		
		if (isClient()) // chain magic
		{
			int movingLinkCount = chain.movingLinkList.get_length();
			int chainSteps = Maths::Max(grapple.chainLength / (chainLinkLength*1.1f), 1);
			
			if (movingLinkCount < chainSteps)
			{
				if (movingLinkCount > 0)
				{
					Vec2f lastLinkPos = chain.movingLinkList[movingLinkCount-1].pos;
					Vec2f lastLinkVec = thisPos - lastLinkPos;
					lastLinkVec.Normalize();
					for (uint i = 0; i < chainSteps-movingLinkCount; i++)
					{
						MovingLink newMovingLink;
						newMovingLink.pos = (lastLinkVec * i)+thisPos;
						newMovingLink.prevPos = thisPos;
						chain.movingLinkList.push_back(newMovingLink);
					}
				}
				else
				{
					for (uint i = 0; i < chainSteps-movingLinkCount; i++)
					{
						MovingLink newMovingLink;
						newMovingLink.pos = (-hookVecNorm)+thisPos;
						newMovingLink.prevPos = thisPos;
						chain.movingLinkList.push_back(newMovingLink);
					}
				}
				movingLinkCount = chain.movingLinkList.get_length();

				/*chain.boneList.clear();

				for (uint i = 0; i < movingLinkCount; i++)
				{
					if (i == 0) continue;

					MovingBone newBone;
					newBone.unit1 = chain.movingLinkList[i-1];
					newBone.unit2 = chain.movingLinkList[i];
					chain.boneList.push_back(newBone);
				}*/
			}

			if (movingLinkCount > 0)
			{
				for (uint i = 0; i < movingLinkCount; i++)
				{
					MovingLink@ thisMovingLink = chain.movingLinkList[i];
					if (i == 0) // closest to hook
					{
						Vec2f beforePosUpdate = thisMovingLink.pos;
						thisMovingLink.pos = hookPos;
						thisMovingLink.prevPos = beforePosUpdate;
					}
					else if (i == movingLinkCount-1) // closest to ship
					{
						Vec2f beforePosUpdate = thisMovingLink.pos;
						thisMovingLink.pos = thisPos;
						thisMovingLink.prevPos = beforePosUpdate;
					}
					else if (!thisMovingLink.locked)
					{
						Vec2f beforePosUpdate = thisMovingLink.pos;
						Vec2f linkMovement = thisMovingLink.pos - thisMovingLink.prevPos;
						thisMovingLink.pos += linkMovement;
						thisMovingLink.prevPos += linkMovement*0.1f;
						thisMovingLink.prevPos = beforePosUpdate;
					}
				}

				for (u8 i = 0; i < 8; i++)
				for (uint i = 0; i < movingLinkCount; i++)
				{
					if ( i == 0) continue; // no anchors
					
					MovingLink@ thisMovingLink = chain.movingLinkList[i];
					MovingLink@ prevMovingLink = chain.movingLinkList[i-1];
					//MovingLink@ nextMovingLink = chain.movingLinkList[i+1];

					Vec2f boneCentre = (prevMovingLink.pos + thisMovingLink.pos) / 2;
					Vec2f boneDir = prevMovingLink.pos - thisMovingLink.pos;
					boneDir.Normalize();

					if (!prevMovingLink.locked)
						prevMovingLink.pos = boneCentre + boneDir * chainLinkLength / 2;
					thisMovingLink.pos = boneCentre - boneDir * chainLinkLength / 2;
				}

				/*
				for (uint i = 0; i < movingLinkCount; i++)
				{
					MovingLink@ thisMovingLink = chain.movingLinkList[i];
					if (i == 0) // closest to hook
					{
						Vec2f beforePosUpdate = thisMovingLink.pos;
						thisMovingLink.pos = hookPos;
						thisMovingLink.prevPos = beforePosUpdate;
					}
					else if (i == movingLinkCount-1) // closest to ship
					{
						Vec2f beforePosUpdate = thisMovingLink.pos;
						thisMovingLink.pos = thisPos;
						thisMovingLink.prevPos = beforePosUpdate;
					}
					else if (!thisMovingLink.locked)
					{
						Vec2f beforePosUpdate = thisMovingLink.pos;
						thisMovingLink.pos += thisMovingLink.pos - thisMovingLink.prevPos;
						thisMovingLink.prevPos = beforePosUpdate;
					}
				}
				
				int movingBoneCount = chain.boneList.get_length();
				for (u8 i = 0; i < 3; i++)
				for (uint i = 0; i < movingBoneCount; i++)
				{
					MovingBone@ thisBone = chain.boneList[i];
					
					Vec2f boneCentre = (thisBone.unit1.pos + thisBone.unit2.pos) / 2;
					Vec2f boneDir = thisBone.unit1.pos - thisBone.unit2.pos;
					boneDir.Normalize();

					if (!thisBone.unit1.locked)
						thisBone.unit1.pos = boneCentre + boneDir * chainLinkLength / 2;
					if (!thisBone.unit2.locked)
						thisBone.unit2.pos = boneCentre - boneDir * chainLinkLength / 2;
				}*/

				// chain render
				makeChain(chain);
			}
		}
		
		if (isServer() && gameTimeVariation % 10 == 0) grappleSync(this, hookBlobNetID, grapple.chainLength, grapple.grappledBlobNetID); // once a second, sync to client
	}
	

	if (!isClient()) return; // client only
	//gun logic
	const bool isShifting = this.get_bool("shifting");
	
	u32 shiftTime = this.get_u32( "shift_heldTime");

	if (isShifting && !isGrappleDeployed)
	{
		shiftTime = Maths::Min(shiftTime+1, grappleMaxTicks);
	}
	else { shiftTime = 0; }
	this.set_u32( "shift_heldTime", shiftTime );

	if (shiftTime == 0) return; // do not bother unless charging it

	//sound logic
	float grapplesoundProgress = this.get_f32("grapplesound_progress");
	float grappleLoad = float(shiftTime) / float(grappleMaxTicks);
	if (grappleLoad != 1.0f)
	{
		grapplesoundProgress += grappleLoad * 0.3f;
		if (grapplesoundProgress >= 1.0f)
		{
			this.getSprite().PlaySound("charged.ogg", 2.0f, 1.2f+(grappleLoad*0.2f));
			grapplesoundProgress -= 1.0f;
		}
	}
	this.set_f32( "grapplesound_progress", grapplesoundProgress );

	if (!this.isMyPlayer()) return; // player only

	const bool pressed_m1 = this.isKeyPressed(key_action1);
	if (pressed_m1)
	{
		float launch_speed = grappleLoad * 10.0f;
		Vec2f launch_vec = Vec2f(2.0f+launch_speed,0);
		launch_vec.RotateByDegrees(blobAngle);
		launch_vec += thisVel;

		CBitStream params;
		params.write_Vec2f(launch_vec);
		this.SendCommandOnlyServer(this.getCommandID(launchGrappleCommandID), params);
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (this == null) return;

	GrappleInfo@ grapple; // global
	if (!this.get( "grappleInfo", @grapple )) return;
	
    if (isServer() && cmd == this.getCommandID(launchGrappleCommandID))
    {
		if (grapple.hookBlobNetID != 0) 
		{
			print("fucked up");
			return;
		}

		Vec2f launch_vec = Vec2f_zero;
		
		if (!params.saferead_Vec2f(launch_vec)) return;

		CBlob@ blob = server_CreateBlob( "spacehook" , this.getTeamNum(), this.getPosition());
		if (blob !is null)
		{
			blob.IgnoreCollisionWhileOverlapped( this );
			blob.SetDamageOwnerPlayer( this.getPlayer() );
			blob.setVelocity( launch_vec );
			blob.set_u16("ownerBlobID", this.getNetworkID());
			
			u16 blobNetID = blob.getNetworkID();
			grapple.hookBlobNetID = blobNetID;
			grappleSync(this, blobNetID);
		}
	}
	else if (cmd == this.getCommandID(grappleSyncCommandID))
	{
		print("ya sync");
		u16 hookBlobNetID = 0;

		if (!params.saferead_u16(hookBlobNetID)) return;

		grapple.hookBlobNetID = hookBlobNetID;
		
		f32 chainLength;
		u16 grappledBlobNetID;

		if (!params.saferead_f32(chainLength) || !params.saferead_u16(grappledBlobNetID))
		{
			chainLength = 0.0f;
			grappledBlobNetID = 0;
		}

		grapple.chainLength = chainLength;
		grapple.grappledBlobNetID = grappledBlobNetID;
	}

	//else if (cmd == this.getCommandID(homing_target_update_ID)) // resets lose target timer for all clients
}