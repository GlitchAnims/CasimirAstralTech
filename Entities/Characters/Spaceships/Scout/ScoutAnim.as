// Scout animations

#include "SpaceshipVars.as"
#include "CommonFX.as"
#include "SpaceshipAnimCommon.as"

Random _scout_anim_r(23177);

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
	this.RemoveSpriteLayer(backwardFire1Name);
	this.RemoveSpriteLayer(portFire1Name);
	this.RemoveSpriteLayer(starboardFire1Name);

	const float frameSizeX = thrustFlashFrameSize.x;
	const float frameSizeY = thrustFlashFrameSize.y;

	CSpriteLayer@ forFire1 			= this.addSpriteLayer(forwardFire1Name, thrustFlashFilename, frameSizeX, frameSizeY);
	CSpriteLayer@ backFire1 		= this.addSpriteLayer(backwardFire1Name, thrustFlashFilename, frameSizeX, frameSizeY);
	CSpriteLayer@ backFire2 		= this.addSpriteLayer(backwardFire2Name, thrustFlashFilename, frameSizeX, frameSizeY);
	CSpriteLayer@ portFire1 		= this.addSpriteLayer(portFire1Name, thrustFlashFilename, frameSizeX, frameSizeY);
	CSpriteLayer@ starboardFire1 	= this.addSpriteLayer(starboardFire1Name, thrustFlashFilename, frameSizeX, frameSizeY);

	if (forFire1 !is null)
	{
		Animation@ anim = forFire1.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = forFire1.addAnimation("boost", 1, true);
		anim2.AddFrames(thrustFrames2);

		forFire1.SetVisible(false);
		forFire1.SetRelativeZ(-1.1f);
		//forFire1.RotateBy(0, Vec2f_zero);
		forFire1.SetOffset(Vec2f(7, 0));
	}
	if (backFire1 !is null)
	{
		Animation@ anim = backFire1.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = backFire1.addAnimation("boost", 1, true);
		anim2.AddFrames(thrustFrames2);

		backFire1.SetVisible(false);
		backFire1.SetRelativeZ(-1.2f);
		backFire1.ScaleBy(0.3f, 0.3f);
		backFire1.RotateBy(180, Vec2f_zero);
		backFire1.SetOffset(Vec2f(-1.0f, -3.5f));
	}
	if (backFire2 !is null)
	{
		Animation@ anim = backFire2.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = backFire2.addAnimation("boost", 1, true);
		anim2.AddFrames(thrustFrames2);

		backFire2.SetVisible(false);
		backFire2.SetRelativeZ(-1.2f);
		backFire2.ScaleBy(0.3f, 0.3f);
		backFire2.RotateBy(180, Vec2f_zero);
		backFire2.SetOffset(Vec2f(-1.0f, 3.5f));
	}
	if (portFire1 !is null)
	{
		Animation@ anim = portFire1.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = portFire1.addAnimation("boost", 1, true);
		anim2.AddFrames(thrustFrames2);

		portFire1.SetVisible(false);
		portFire1.SetRelativeZ(-1.3f);
		portFire1.ScaleBy(0.3f, 0.3f);
		portFire1.RotateBy(270, Vec2f_zero);
		portFire1.SetOffset(Vec2f(4, 9));
	}
	if (starboardFire1 !is null)
	{
		Animation@ anim = starboardFire1.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = starboardFire1.addAnimation("boost", 1, true);
		anim2.AddFrames(thrustFrames2);

		starboardFire1.SetVisible(false);
		starboardFire1.SetRelativeZ(-1.4f);
		starboardFire1.ScaleBy(0.3f, 0.3f);
		starboardFire1.RotateBy(90, Vec2f_zero);
		starboardFire1.SetOffset(Vec2f(4, -9));
	}
	
}

void onTick(CSprite@ this)
{
	// store some vars for ease and speed
	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null)
	{ return; }

	Vec2f blobPos = thisBlob.getPosition();
	Vec2f blobVel = thisBlob.getVelocity();
	f32 blobAngle = thisBlob.getAngleDegrees();
	blobAngle = (blobAngle+360.0f) % 360;
	Vec2f aimpos;
	int teamNum = thisBlob.getTeamNum();

	SpaceshipVars@ moveVars;
	if (!thisBlob.get("moveVars", @moveVars)) return;

	const bool isBoost = moveVars.is_boost;
	string animationName = isBoost ? "boost" : "default";
	const bool changeAnim = thisBlob.get_bool(boostAnimBoolString) != isBoost || _ship_anim_r.NextFloat() < 0.001f;
	thisBlob.set_bool(boostAnimBoolString, isBoost);

	//set engine burns to correct visibility
	CSpriteLayer@ forFire1			= this.getSpriteLayer(forwardFire1Name);
	CSpriteLayer@ backFire1			= this.getSpriteLayer(backwardFire1Name);
	CSpriteLayer@ backFire2			= this.getSpriteLayer(backwardFire2Name);
	CSpriteLayer@ portFire1			= this.getSpriteLayer(portFire1Name);
	CSpriteLayer@ starboardFire1	= this.getSpriteLayer(starboardFire1Name);

	bool mainEngine = moveVars.forward_thrust;
	if (forFire1 !is null)
	{
		forFire1.SetVisible(mainEngine);
		if (changeAnim) forFire1.SetAnimation(animationName);
	}
	if (backFire1 !is null)
	{
		backFire1.SetVisible(moveVars.backward_thrust);
		if (changeAnim) backFire1.SetAnimation(animationName);
	}
	if (backFire2 !is null)
	{
		backFire2.SetVisible(moveVars.backward_thrust);
		if (changeAnim) backFire2.SetAnimation(animationName);
	}
	if (portFire1 !is null)
	{
		portFire1.SetVisible(moveVars.port_thrust);
		if (changeAnim) portFire1.SetAnimation(animationName);
	}
	if (starboardFire1 !is null)
	{
		starboardFire1.SetVisible(moveVars.starboard_thrust);
		if (changeAnim) starboardFire1.SetAnimation(animationName);
	}

	if (mainEngine)
	{
		Vec2f engineOffset = Vec2f(-6.0f, 0);
		engineOffset.RotateByDegrees(blobAngle);
		Vec2f trailPos = blobPos + engineOffset;

		makeEngineTrail(trailPos, false, 7, blobVel, blobAngle+90.0f, teamNum);
	}
}