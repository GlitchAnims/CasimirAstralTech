// Bomber animations

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
	this.RemoveSpriteLayer(backwardFire1Name);
	this.RemoveSpriteLayer(portFire1Name);
	this.RemoveSpriteLayer(starboardFire1Name);

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
		Animation@ anim2 = forFire1.addAnimation("boost", 1, true);
		anim2.AddFrames(thrustFrames2);
		
		forFire1.SetVisible(false);
		forFire1.SetRelativeZ(-1.1f);
		//forFire1.RotateBy(0, Vec2f_zero);
		forFire1.SetOffset(Vec2f(7.5f, 5.5f));
	}
	if (forFire2 !is null)
	{
		Animation@ anim = forFire2.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = forFire2.addAnimation("boost", 1, true);
		anim2.AddFrames(thrustFrames2);
		
		forFire2.SetVisible(false);
		forFire2.SetRelativeZ(-1.1f);
		//forFire2.RotateBy(0, Vec2f_zero);
		forFire2.SetOffset(Vec2f(7.5f, -5.5f));
	}
	if (backFire1 !is null)
	{
		Animation@ anim = backFire1.addAnimation("default", 2, true);
		anim.AddFrames(thrustFrames1);
		Animation@ anim2 = backFire1.addAnimation("boost", 1, true);
		anim2.AddFrames(thrustFrames2);
		
		backFire1.SetVisible(false);
		backFire1.SetRelativeZ(-1.2f);
		backFire1.ScaleBy(0.5f, 0.5f);
		backFire1.RotateBy(180, Vec2f_zero);
		backFire1.SetOffset(Vec2f(-6, 0));
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
		portFire1.SetOffset(Vec2f(0, 8));
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
		starboardFire1.SetOffset(Vec2f(0, -8));
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
	CSpriteLayer@ forFire2			= this.getSpriteLayer(forwardFire2Name);
	CSpriteLayer@ backFire1			= this.getSpriteLayer(backwardFire1Name);
	CSpriteLayer@ portFire1			= this.getSpriteLayer(portFire1Name);
	CSpriteLayer@ starboardFire1	= this.getSpriteLayer(starboardFire1Name);

	bool mainEngine = moveVars.forward_thrust;
	if (forFire1 !is null)
	{
		forFire1.SetVisible(mainEngine);
		if (changeAnim) forFire1.SetAnimation(animationName);
	}
	if (forFire2 !is null)
	{
		forFire2.SetVisible(mainEngine);
		if (changeAnim) forFire2.SetAnimation(animationName);
	}
	if (backFire1 !is null)
	{
		backFire1.SetVisible(moveVars.backward_thrust);
		if (changeAnim) backFire1.SetAnimation(animationName);
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
		Vec2f engineOffset = Vec2f(-6.0f, -5.5f);
		engineOffset.RotateByDegrees(blobAngle);
		Vec2f trailPos = blobPos + engineOffset;

		makeEngineTrail(trailPos, false, 4, blobVel, blobAngle+90.0f, teamNum);

		engineOffset = Vec2f(-6.0f, 5.5f);
		engineOffset.RotateByDegrees(blobAngle);
		trailPos = blobPos + engineOffset;

		makeEngineTrail(trailPos, false, 4, blobVel, blobAngle+90.0f, teamNum);
	}
}