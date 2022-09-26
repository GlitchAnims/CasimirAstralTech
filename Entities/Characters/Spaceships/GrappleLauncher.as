#include "GrappleCommon.as"

void onInit( CBlob@ this )
{
	this.set_u32( "shift_heldTime", 0 );
	
	GrappleInfo grapple;
	grapple.isDeployed = false;
	grapple.hookBlobNetID = 0;
	grapple.chainLength = 0.0f;
	grapple.grappledBlobNetID = 0;
	this.set("grappleInfo", @grapple);

	if (isClient())
	{
		ChainInfo chain;
		this.set("chainInfo", @chain);

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

	const bool isGrappleDeployed = grapple.isDeployed;
	const u16 hookBlobNetID = grapple.hookBlobNetID;

	if (isGrappleDeployed)
	{
		if (hookBlobNetID != 0)
		{
			CBlob@ hookBlob = getBlobByNetworkID(hookBlobNetID);
			if (hookBlob == null)
			{
				grappleSync(this);
			}
			else
			{
				u16 grappledBlobNetID = grapple.grappledBlobNetID;

				float chainLength = grapple.chainLength;
				Vec2f hookPos = hookBlob.getPosition();
				Vec2f hookVec = hookPos - thisPos;
				float hookDist = hookVec.getLength();

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
					Vec2f hookVecNorm = hookVec;
					hookVecNorm.Normalize();

					float thisMass = this.getMass();
					float grappledMass = grappledBlob.getMass();
					float massRatio = thisMass/grappledMass;

					float pullDist = Maths::Max(hookDist-chainLength, 0.0f);

					if (pullDist > 0)
					{
						float pullStrength = Maths::FastSqrt(pullDist);
						
						this.setPosition(thisPos + (hookVecNorm*pullDist));
						this.setVelocity(thisVel + (hookVecNorm*0.1f));
						grappledBlob.AddForceAtPosition(-hookVecNorm*pullStrength*massRatio*4.0f, hookPos);
					}
				}

				makeStraightChain(hookPos, thisPos);
				if (isServer() && gameTimeVariation % 30 == 0) grappleSync(this, isGrappleDeployed, hookBlobNetID, chainLength, grapple.grappledBlobNetID); // once a second, sync to client
			}
		}
	}
	else
	{
		grapple.chainLength = 0;
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
		float launch_speed = grappleLoad * 5.0f;
		Vec2f launch_vec = Vec2f(1.0f+launch_speed,0);
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
		if (grapple.isDeployed) return;

		Vec2f launch_vec = Vec2f_zero;
		
		if (!params.saferead_Vec2f(launch_vec)) return;

		CBlob@ blob = server_CreateBlob( "spacehook" , this.getTeamNum(), this.getPosition());
		if (blob !is null)
		{
			blob.IgnoreCollisionWhileOverlapped( this );
			blob.SetDamageOwnerPlayer( this.getPlayer() );
			blob.setVelocity( launch_vec );
			blob.set_u16("ownerBlobID", this.getNetworkID());

			grapple.isDeployed = true;
			grappleSync(this, true, blob.getNetworkID());
		}
	}
	else if (cmd == this.getCommandID(grappleSyncCommandID))
	{
		bool isDeployed;
		u16 hookBlobNetID;

		if (!params.saferead_bool(isDeployed) || !params.saferead_u16(hookBlobNetID)) return;

		grapple.isDeployed = isDeployed;
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