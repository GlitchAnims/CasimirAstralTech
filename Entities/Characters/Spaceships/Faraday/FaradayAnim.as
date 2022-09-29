// Knight animations

#include "SpaceshipVars.as"
#include "CommonFX.as"
#include "SpaceshipAnimCommon.as"
#include "FaradayCommon.as"

void onInit(CSprite@ this)
{
	LoadSprites(this);
	this.getBlob().set_bool(boostAnimBoolString, false);
}

void onPlayerInfoChanged(CSprite@ this)
{
	LoadSprites(this);
}

void LoadSprites(CSprite@ this)
{
	// add engine fires
	this.RemoveSpriteLayer(forwardFire1Name);
	this.RemoveSpriteLayer(forwardFire2Name);
	this.RemoveSpriteLayer(backwardFire1Name);
	this.RemoveSpriteLayer(backwardFire2Name);
	this.RemoveSpriteLayer(portFire1Name);
	this.RemoveSpriteLayer(portFire2Name);
	this.RemoveSpriteLayer(starboardFire1Name);
	this.RemoveSpriteLayer(starboardFire2Name);

	const float frameSizeX = thrustFlashFrameSize.x;
	const float frameSizeY = thrustFlashFrameSize.y;

	CSpriteLayer@ forFire1 			= this.addSpriteLayer(forwardFire1Name, thrustFlashFilename, frameSizeX, frameSizeY);
	CSpriteLayer@ forFire2 			= this.addSpriteLayer(forwardFire2Name, thrustFlashFilename, frameSizeX, frameSizeY);
	CSpriteLayer@ backFire1 		= this.addSpriteLayer(backwardFire1Name, thrustFlashFilename, frameSizeX, frameSizeY);
	CSpriteLayer@ portFire1 		= this.addSpriteLayer(portFire1Name, thrustFlashFilename, frameSizeX, frameSizeY);
	CSpriteLayer@ starboardFire1 	= this.addSpriteLayer(starboardFire1Name, thrustFlashFilename, frameSizeX, frameSizeY);
	if (forFire1 !is null)
	{
		Animation@ anim = forFire1.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = forFire1.addAnimation("warp", 2, true);
		anim2.AddFrames(thrustFrames3);
		forFire1.SetVisible(false);
		forFire1.SetRelativeZ(-5.0f);
		forFire1.ScaleBy(1.2f, 1.2f);
		//forFire1.RotateBy(-90, Vec2f_zero);
		forFire1.SetOffset(Vec2f(17.0f, -7.5f));
	}
	if (forFire2 !is null)
	{
		Animation@ anim = forFire2.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = forFire2.addAnimation("warp", 2, true);
		anim2.AddFrames(thrustFrames3);
		forFire2.SetVisible(false);
		forFire2.SetRelativeZ(-5.0f);
		forFire2.ScaleBy(1.2f, 1.2f);
		//forFire2.RotateBy(-90, Vec2f_zero);
		forFire2.SetOffset(Vec2f(17.0f, 7.5f));
	}
	if (backFire1 !is null)
	{
		Animation@ anim = backFire1.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = backFire1.addAnimation("warp", 2, true);
		anim2.AddFrames(thrustFrames3);
		backFire1.SetVisible(false);
		backFire1.SetRelativeZ(-5.0f);
		backFire1.ScaleBy(1.2f, 1.2f);
		backFire1.RotateBy(180.0f, Vec2f_zero);
		backFire1.SetOffset(Vec2f(-10.0f, 0.0f));
	}
	if (portFire1 !is null)
	{
		Animation@ anim = portFire1.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = portFire1.addAnimation("warp", 2, true);
		anim2.AddFrames(thrustFrames3);
		portFire1.SetVisible(false);
		portFire1.SetRelativeZ(-5.0f);
		portFire1.ScaleBy(1.2f, 1.2f);
		portFire1.RotateBy(90, Vec2f_zero);
		portFire1.SetOffset(Vec2f(0.0f, -15.0f));
	}
	if (starboardFire1 !is null)
	{
		Animation@ anim = starboardFire1.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = starboardFire1.addAnimation("warp", 2, true);
		anim2.AddFrames(thrustFrames3);
		starboardFire1.SetVisible(false);
		starboardFire1.SetRelativeZ(-5.0f);
		starboardFire1.ScaleBy(1.2f, 1.2f);
		starboardFire1.RotateBy(-90, Vec2f_zero);
		starboardFire1.SetOffset(Vec2f(0.0f, 15.0f));
	}

	this.RemoveSpriteLayer(faradayUndersideName);
	CSpriteLayer@ faradayUndersideLayer	= this.addSpriteLayer(faradayUndersideName, "Faraday.png", 40, 40);

	if (faradayUndersideLayer !is null)
	{
		faradayUndersideLayer.SetVisible(true);
		faradayUndersideLayer.SetFrame(14);
		faradayUndersideLayer.SetRelativeZ(-2.5f);
		//faradayUndersideLayer.ScaleBy(1.2f, 1.2f);
		//faradayUndersideLayer.RotateBy(-90, Vec2f_zero);
		//faradayUndersideLayer.SetOffset(Vec2f(0.0f, 15.0f));
	}
}

void onTick(CSprite@ this)
{
	// store some vars for ease and speed
	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null) return;

	Vec2f blobPos = thisBlob.getPosition();
	Vec2f blobVel = thisBlob.getVelocity();
	f32 blobAngle = thisBlob.getAngleDegrees();
	blobAngle = (blobAngle+360.0f) % 360;
	Vec2f aimpos;
	int teamNum = thisBlob.getTeamNum();

	SpaceshipVars@ moveVars;
	if (!thisBlob.get("moveVars", @moveVars)) return;
	
	const bool isWarp = moveVars.is_warp;
	string animationName = isWarp ? "warp" : "default";
	const bool changeAnim = thisBlob.get_bool(boostAnimBoolString) != isWarp || _ship_anim_r.NextFloat() < 0.001f;
	thisBlob.set_bool(boostAnimBoolString, isWarp);

	CSpriteLayer@ faradayUndersideLayer	= this.getSpriteLayer(faradayUndersideName);

	u16 frame = 0;
	u16 frame_under = 14;
	u8 faradayTime = thisBlob.get_u8(faradayTimeString);
	u8 faradayPhase = thisBlob.get_u8(faradayPhaseString);
	u8 faradayNext = thisBlob.get_u8(faradayNextString);

	const bool warpPhase = faradayPhase == 1 || faradayPhase == 2;
	const bool assaultPhase = faradayPhase == 2 || faradayPhase == 3;

	if (warpPhase) frame = 13;
	if (assaultPhase) frame_under = 27;

	//bool faradayWasWarp = thisBlob.get_bool("faraday_was_warp");
	//bool faradayWasAssault = thisBlob.get_bool("faraday_was_assault");
	if (faradayNext != faradayPhase)
	{
		const bool warpNextPhase = faradayNext == 1 || faradayNext == 2;
		const bool assaultNextPhase = faradayNext == 2 || faradayNext == 3;

		if (!warpPhase && warpNextPhase) 			frame = ((45.0f-float(faradayTime)) / 45.0f) * 13.0f;
		else if(warpPhase && !warpNextPhase) 		frame = (float(faradayTime) / 45.0f) * 13.0f;

		if (!assaultPhase && assaultNextPhase) 		frame_under += ((45.0f-float(faradayTime)) / 45.0f) * 13.0f;
		else if(assaultPhase && !assaultNextPhase) 	frame_under -= ((45.0f-float(faradayTime)) / 45.0f) * 13.0f;
	}

	this.SetFrame(frame);
	if (faradayUndersideLayer != null) faradayUndersideLayer.SetFrame(frame_under);
	
	//set engine fires to correct places
	CSpriteLayer@ forFire1			= this.getSpriteLayer(forwardFire1Name);
	CSpriteLayer@ forFire2			= this.getSpriteLayer(forwardFire2Name);
	CSpriteLayer@ backFire1			= this.getSpriteLayer(backwardFire1Name);
	CSpriteLayer@ portFire1			= this.getSpriteLayer(portFire1Name);
	CSpriteLayer@ starboardFire1	= this.getSpriteLayer(starboardFire1Name);

	bool mainEngine = moveVars.forward_thrust;
	bool secEngine = moveVars.backward_thrust;
	bool leftEngine = moveVars.port_thrust;
	bool rightEngine = moveVars.starboard_thrust;

	if (forFire1 !is null) //forward engines
	{
		forFire1.SetVisible(mainEngine);
		if (changeAnim) forFire1.SetAnimation(animationName);

		if (isWarp)
		{
			forFire1.SetOffset(Vec2f(17.0f, -7.5f));
		}
		else
		{
			forFire1.SetOffset(Vec2f(12.0f, 0));
		}
	}
	if (forFire2 !is null)
	{
		forFire2.SetVisible(mainEngine && isWarp);
		if (changeAnim) forFire2.SetAnimation(animationName);
	}

	if (backFire1 !is null) //backwards engines
	{
		backFire1.SetVisible(secEngine);
		if (changeAnim) backFire1.SetAnimation(animationName);

		backFire1.ResetTransform();
		backFire1.ScaleBy(1.2f, 1.2f);
		backFire1.RotateBy(180.0f, Vec2f_zero);
	}
	if (portFire1 !is null)//left side engines
	{
		portFire1.SetVisible(leftEngine);
		if (changeAnim) portFire1.SetAnimation(animationName);
	}
	if (starboardFire1 !is null)//right side engines
	{
		starboardFire1.SetVisible(rightEngine);
		if (changeAnim) starboardFire1.SetAnimation(animationName);
	}
	
	if (mainEngine)
	{
		if (isWarp)
		{
			Vec2f engineOffset = Vec2f(-17.0f, -7.5f);
			engineOffset.RotateByDegrees(blobAngle);
			Vec2f trailPos = blobPos + engineOffset;

			makeEngineTrail(trailPos, false, 3, blobVel, blobAngle+90.0f, teamNum, 2.0f);

			engineOffset = Vec2f(-17.0f, 7.5f);
			engineOffset.RotateByDegrees(blobAngle);
			trailPos = blobPos + engineOffset;

			makeEngineTrail(trailPos, false, 3, blobVel, blobAngle+90.0f, teamNum, 2.0f);
		}
		else
		{
			Vec2f engineOffset = Vec2f(-12.0f, 0);
			engineOffset.RotateByDegrees(blobAngle);
			Vec2f trailPos = blobPos + engineOffset;

			makeEngineTrail(trailPos, false, 3, blobVel, blobAngle+90.0f, teamNum, 1.0f);
		}
	}
}

/*
void onGib(CSprite@ this)
{
	if (g_kidssafe)
	{
		return;
	}

	CBlob@ blob = this.getBlob();
	Vec2f pos = thisBlob.getPosition();
	Vec2f vel = thisBlob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(thisBlob.getHealth()), 2.0f) + 1.0f;
	const u8 team = thisBlob.getTeamNum();
	CParticle@ Body     = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 0, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm      = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Shield   = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 2, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
	CParticle@ Sword    = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 80), 3, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
}


// render cursors

void DrawCursorAt(Vec2f position, string& in filename)
{
	position = getMap().getAlignedWorldPos(position);
	if (position == Vec2f_zero) return;
	position = getDriver().getScreenPosFromWorldPos(position - Vec2f(1, 1));
	GUI::DrawIcon(filename, position, getCamera().targetDistance * getDriver().getResolutionScaleFactor());
}

const string cursorTexture = "Entities/Characters/Sprites/TileCursor.png";

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (!thisBlob.isMyPlayer())
	{
		return;
	}
	if (getHUD().hasButtons())
	{
		return;
	}

	// draw tile cursor

	if (thisBlob.isKeyPressed(key_action1))
	{
		CMap@ map = thisBlob.getMap();
		Vec2f position = thisBlob.getPosition();
		Vec2f cursor_position = thisBlob.getAimPos();
		Vec2f surface_position;
		map.rayCastSolid(position, cursor_position, surface_position);
		Vec2f vector = surface_position - position;
		f32 distance = vector.getLength();
		Tile tile = map.getTile(surface_position);

		if ((map.isTileSolid(tile) || map.isTileGrass(tile.type)) && map.getSectorAtPosition(surface_position, "no build") is null && distance < 16.0f)
		{
			DrawCursorAt(surface_position, cursorTexture);
		}
	}
}*/
