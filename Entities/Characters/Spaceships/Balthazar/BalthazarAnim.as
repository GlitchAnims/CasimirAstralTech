#include "SpaceshipVars.as"
#include "CommonFX.as"
#include "SpaceshipAnimCommon.as"

void onInit(CSprite@ this)
{
	LoadSprites(this);
}

void onPlayerInfoChanged(CSprite@ this)
{
	LoadSprites(this);
}

void LoadSprites(CSprite@ this)
{
	// add engine burns
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
	CSpriteLayer@ backFire2 		= this.addSpriteLayer(backwardFire2Name, thrustFlashFilename, frameSizeX, frameSizeY);
	CSpriteLayer@ portFire1 		= this.addSpriteLayer(portFire1Name, thrustFlashFilename, frameSizeX, frameSizeY);
	CSpriteLayer@ portFire2 		= this.addSpriteLayer(portFire2Name, thrustFlashFilename, frameSizeX, frameSizeY);
	CSpriteLayer@ starboardFire1 	= this.addSpriteLayer(starboardFire1Name, thrustFlashFilename, frameSizeX, frameSizeY);
	CSpriteLayer@ starboardFire2 	= this.addSpriteLayer(starboardFire2Name, thrustFlashFilename, frameSizeX, frameSizeY);
	if (forFire1 !is null)
	{
		Animation@ anim = forFire1.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = forFire1.addAnimation("warp", 2, true);
		anim2.AddFrames(thrustFrames3);
		forFire1.SetVisible(false);
		forFire1.SetRelativeZ(-1.1f);
		forFire1.ScaleBy(0.2f, 0.2f);
		forFire1.RotateBy(-90, Vec2f_zero);
		forFire1.SetOffset(Vec2f(9.5f, 31.0f));
	}
	if (forFire2 !is null)
	{
		Animation@ anim = forFire2.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = forFire2.addAnimation("warp", 2, true);
		anim2.AddFrames(thrustFrames3);
		forFire2.SetVisible(false);
		forFire2.SetRelativeZ(-1.1f);
		forFire2.RotateBy(-90, Vec2f_zero);
		forFire2.SetOffset(Vec2f(-3.5f, 30.0f));
	}
	if (backFire1 !is null)
	{
		Animation@ anim = backFire1.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = backFire1.addAnimation("warp", 2, true);
		anim2.AddFrames(thrustFrames3);
		backFire1.SetVisible(false);
		backFire1.SetRelativeZ(-1.2f);
		backFire1.ScaleBy(0.5f, 0.5f);
		backFire1.RotateBy(90, Vec2f_zero);
		backFire1.SetOffset(Vec2f(11.0f, 17.0f));
	}
	if (backFire2 !is null)
	{
		Animation@ anim = backFire2.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = backFire2.addAnimation("warp", 2, true);
		anim2.AddFrames(thrustFrames3);
		backFire2.SetVisible(false);
		backFire2.SetRelativeZ(-1.2f);
		backFire2.ScaleBy(0.5f, 0.5f);
		backFire2.RotateBy(90, Vec2f_zero);
		backFire2.SetOffset(Vec2f(-9.0f, 12.0f));
	}
	if (portFire1 !is null)
	{
		Animation@ anim = portFire1.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = portFire1.addAnimation("warp", 2, true);
		anim2.AddFrames(thrustFrames3);
		portFire1.SetVisible(false);
		portFire1.SetRelativeZ(-1.3f);
		portFire1.ScaleBy(0.3f, 0.3f);
		//portFire1.RotateBy(180, Vec2f_zero);
		portFire1.SetOffset(Vec2f(9.5f, -17.0f));
	}
	if (portFire2 !is null)
	{
		Animation@ anim = portFire2.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = portFire2.addAnimation("warp", 2, true);
		anim2.AddFrames(thrustFrames3);
		portFire2.SetVisible(false);
		portFire2.SetRelativeZ(-1.3f);
		portFire2.ScaleBy(0.3f, 0.3f);
		//portFire2.RotateBy(180, Vec2f_zero);
		portFire2.SetOffset(Vec2f(14.5f, 25.0f));
	}
	if (starboardFire1 !is null)
	{
		Animation@ anim = starboardFire1.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = starboardFire1.addAnimation("warp", 2, true);
		anim2.AddFrames(thrustFrames3);
		starboardFire1.SetVisible(false);
		starboardFire1.SetRelativeZ(-1.4f);
		starboardFire1.ScaleBy(0.3f, 0.3f);
		starboardFire1.RotateBy(180, Vec2f_zero);
		starboardFire1.SetOffset(Vec2f(-10.5f, -17.0f));
	}
	if (starboardFire2 !is null)
	{
		Animation@ anim = starboardFire2.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = starboardFire2.addAnimation("warp", 2, true);
		anim2.AddFrames(thrustFrames3);
		starboardFire2.SetVisible(false);
		starboardFire2.SetRelativeZ(-1.4f);
		starboardFire2.ScaleBy(0.3f, 0.3f);
		starboardFire2.RotateBy(180, Vec2f_zero);
		starboardFire2.SetOffset(Vec2f(-11.5f, 25.0f));
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
	bool facingLeft = this.isFacingLeft();
	int teamNum = thisBlob.getTeamNum();

	SpaceshipVars@ moveVars;
	if (!thisBlob.get("moveVars", @moveVars)) return;
	
	const bool isWarp = moveVars.is_warp;
	string animationName = isWarp ? "warp" : "default";
	const bool changeAnim = thisBlob.get_bool(boostAnimBoolString) != isWarp || _ship_anim_r.NextFloat() < 0.001f;
	thisBlob.set_bool(boostAnimBoolString, isWarp);
	
	//set engine fires to correct places
	CSpriteLayer@ forFire1		= this.getSpriteLayer(forwardFire1Name);
	CSpriteLayer@ forFire2		= this.getSpriteLayer(forwardFire2Name);
	CSpriteLayer@ backFire1		= this.getSpriteLayer(backwardFire1Name);
	CSpriteLayer@ backFire2		= this.getSpriteLayer(backwardFire2Name);
	CSpriteLayer@ portFire1		= this.getSpriteLayer(portFire1Name);
	CSpriteLayer@ portFire2		= this.getSpriteLayer(portFire2Name);
	CSpriteLayer@ starboardFire1	= this.getSpriteLayer(starboardFire1Name);
	CSpriteLayer@ starboardFire2	= this.getSpriteLayer(starboardFire2Name);

	bool mainEngine = moveVars.forward_thrust || isWarp;
	bool secEngine = moveVars.backward_thrust && !isWarp;
	bool leftEngine = moveVars.port_thrust;
	bool leftFrontEngine = moveVars.portBow_thrust;
	bool leftBackEngine = moveVars.portQuarter_thrust;
	bool rightEngine = moveVars.starboard_thrust;
	bool rightFrontEngine = moveVars.starboardBow_thrust;
	bool rightBackEngine = moveVars.starboardQuarter_thrust;

	f32 leftFlipDegrees = facingLeft ? 180.0f : 0.0f;
	if (forFire1 !is null) //forward engines
	{
		forFire1.SetVisible(mainEngine);
		if (changeAnim) forFire1.SetAnimation(animationName);

		forFire1.ResetTransform();
		forFire1.ScaleBy(0.8f, 0.8f);
		forFire1.RotateBy(-90.0f + leftFlipDegrees, Vec2f_zero);
	}
	if (forFire2 !is null)
	{
		forFire2.SetVisible(mainEngine);
		if (changeAnim) forFire2.SetAnimation(animationName);

		forFire2.ResetTransform();
		forFire2.RotateBy(-90 + leftFlipDegrees, Vec2f_zero);
	}

	if (backFire1 !is null) //backwards engines
	{
		backFire1.SetVisible(secEngine);
		if (changeAnim) backFire1.SetAnimation(animationName);

		backFire1.ResetTransform();
		backFire1.ScaleBy(0.5f, 0.5f);
		backFire1.RotateBy(90 + leftFlipDegrees, Vec2f_zero);
	}
	if (backFire2 !is null)
	{
		backFire2.SetVisible(secEngine);
		if (changeAnim) backFire2.SetAnimation(animationName);

		backFire2.ResetTransform();
		backFire2.ScaleBy(0.5f, 0.5f);
		backFire2.RotateBy(90 + leftFlipDegrees, Vec2f_zero);
	}
	
	if (portFire1 !is null)//left side engines
	{
		portFire1.SetVisible(leftEngine || leftFrontEngine);
		if (changeAnim) portFire1.SetAnimation(animationName);
	}
	if (portFire2 !is null)
	{
		portFire2.SetVisible(leftEngine || leftBackEngine);
		if (changeAnim) portFire2.SetAnimation(animationName);
	}

	if (starboardFire1 !is null)//right side engines
	{
		starboardFire1.SetVisible(rightEngine || rightFrontEngine);
		if (changeAnim) starboardFire1.SetAnimation(animationName);
	}
	if (starboardFire2 !is null)
	{
		starboardFire2.SetVisible(rightEngine || rightBackEngine);
		if (changeAnim) starboardFire2.SetAnimation(animationName);
	}

	if (mainEngine || isWarp)
	{
		Vec2f engineOffset = Vec2f(facingLeft ? 9.5f: -9.5f, 32.0f);
		engineOffset.RotateByDegrees(blobAngle);
		Vec2f trailPos = blobPos + engineOffset;

		makeEngineTrail(trailPos, isWarp, 2, blobVel, blobAngle, teamNum);

		engineOffset = Vec2f(facingLeft ? -3.5f : 3.5f , 31.0f);
		engineOffset.RotateByDegrees(blobAngle);
		trailPos = blobPos + engineOffset;

		makeEngineTrail(trailPos, isWarp, 4, blobVel, blobAngle, teamNum);
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
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0f;
	const u8 team = blob.getTeamNum();
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
	if (!blob.isMyPlayer())
	{
		return;
	}
	if (getHUD().hasButtons())
	{
		return;
	}

	// draw tile cursor

	if (blob.isKeyPressed(key_action1))
	{
		CMap@ map = blob.getMap();
		Vec2f position = blob.getPosition();
		Vec2f cursor_position = blob.getAimPos();
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
