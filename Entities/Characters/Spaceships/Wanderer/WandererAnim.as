// Knight animations

#include "MediumshipCommon.as";
#include "RunnerAnimCommon.as";
#include "RunnerCommon.as";
#include "KnockedCommon.as";
#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "CommonFX.as"
#include "ShieldCommon.as"

const string up_fire1 = "forward_burn1";
const string up_fire2 = "forward_burn2";
const string down_fire1 = "backward_burn1";
const string down_fire2 = "backward_burn2";
const string left_fire1 = "port_burn1";
const string left_fire2 = "port_burn2";
const string right_fire1 = "starboard_burn1";
const string right_fire2 = "starboard_burn2";

Random _martyr_anim_r(65444);

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

	// add shiny
	/*
	this.RemoveSpriteLayer(shiny_layer);
	CSpriteLayer@ shiny = this.addSpriteLayer(shiny_layer, "AnimeShiny.png", 16, 16);
	if (shiny !is null)
	{
		Animation@ anim = shiny.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		shiny.SetVisible(false);
		shiny.SetRelativeZ(1.0f);
	}*/

	// add engine burns
	this.RemoveSpriteLayer(up_fire1);
	this.RemoveSpriteLayer(up_fire2);
	this.RemoveSpriteLayer(down_fire1);
	this.RemoveSpriteLayer(down_fire2);
	this.RemoveSpriteLayer(left_fire1);
	this.RemoveSpriteLayer(left_fire2);
	this.RemoveSpriteLayer(right_fire1);
	this.RemoveSpriteLayer(right_fire2);
	CSpriteLayer@ upFire1 		= this.addSpriteLayer(up_fire1, "ThrustFlash.png", 27, 27);
	CSpriteLayer@ upFire2 		= this.addSpriteLayer(up_fire2, "ThrustFlash.png", 27, 27);
	CSpriteLayer@ downFire1 	= this.addSpriteLayer(down_fire1, "ThrustFlash.png", 27, 27);
	CSpriteLayer@ downFire2 	= this.addSpriteLayer(down_fire2, "ThrustFlash.png", 27, 27);
	CSpriteLayer@ leftFire1 	= this.addSpriteLayer(left_fire1, "ThrustFlash.png", 27, 27);
	CSpriteLayer@ leftFire2 	= this.addSpriteLayer(left_fire2, "ThrustFlash.png", 27, 27);
	CSpriteLayer@ rightFire1 	= this.addSpriteLayer(right_fire1, "ThrustFlash.png", 27, 27);
	CSpriteLayer@ rightFire2 	= this.addSpriteLayer(right_fire2, "ThrustFlash.png", 27, 27);
	if (upFire1 !is null)
	{
		Animation@ anim = upFire1.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		upFire1.SetVisible(false);
		upFire1.SetRelativeZ(-1.1f);
		upFire1.ScaleBy(0.8f, 0.8f);
		upFire1.RotateBy(-90, Vec2f_zero);
		upFire1.SetOffset(Vec2f(8.0f, 31.0f));
	}
	if (upFire2 !is null)
	{
		Animation@ anim = upFire2.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		upFire2.SetVisible(false);
		upFire2.SetRelativeZ(-1.1f);
		upFire2.ScaleBy(0.8f, 0.8f);
		upFire2.RotateBy(-90, Vec2f_zero);
		upFire2.SetOffset(Vec2f(-8.0f, 31.0f));
	}
	if (downFire1 !is null)
	{
		Animation@ anim = downFire1.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		downFire1.SetVisible(false);
		downFire1.SetRelativeZ(-1.2f);
		downFire1.ScaleBy(0.5f, 0.5f);
		downFire1.RotateBy(90, Vec2f_zero);
		downFire1.SetOffset(Vec2f(11.0f, 17.0f));
	}
	if (downFire2 !is null)
	{
		Animation@ anim = downFire2.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		downFire2.SetVisible(false);
		downFire2.SetRelativeZ(-1.2f);
		downFire2.ScaleBy(0.5f, 0.5f);
		downFire2.RotateBy(90, Vec2f_zero);
		downFire2.SetOffset(Vec2f(-9.0f, 12.0f));
	}
	if (leftFire1 !is null)
	{
		Animation@ anim = leftFire1.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		leftFire1.SetVisible(false);
		leftFire1.SetRelativeZ(-1.3f);
		leftFire1.ScaleBy(0.3f, 0.3f);
		leftFire1.RotateBy(180, Vec2f_zero);
		leftFire1.SetOffset(Vec2f(-10.0f, -21.0f));
	}
	if (leftFire2 !is null)
	{
		Animation@ anim = leftFire2.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		leftFire2.SetVisible(false);
		leftFire2.SetRelativeZ(-1.3f);
		leftFire2.ScaleBy(0.3f, 0.3f);
		leftFire2.RotateBy(180, Vec2f_zero);
		leftFire2.SetOffset(Vec2f(-15.0f, 22.0f));
	}
	if (rightFire1 !is null)
	{
		Animation@ anim = rightFire1.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		rightFire1.SetVisible(false);
		rightFire1.SetRelativeZ(-1.4f);
		rightFire1.ScaleBy(0.3f, 0.3f);
		//rightFire1.RotateBy(180, Vec2f_zero);
		rightFire1.SetOffset(Vec2f(10.0f, -21.0f));
	}
	if (rightFire2 !is null)
	{
		Animation@ anim = rightFire2.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		rightFire2.SetVisible(false);
		rightFire2.SetRelativeZ(-1.4f);
		rightFire2.ScaleBy(0.3f, 0.3f);
		//rightFire2.RotateBy(180, Vec2f_zero);
		rightFire2.SetOffset(Vec2f(15.0f, 22.0f));
	}
	
}

void onTick(CSprite@ this)
{
	// store some vars for ease and speed
	CBlob@ blob = this.getBlob();
	if (blob == null)
	{ return; }

	Vec2f blobPos = blob.getPosition();
	Vec2f blobVel = blob.getVelocity();
	f32 blobAngle = blob.getAngleDegrees();
	blobAngle = (blobAngle+360.0f) % 360;
	Vec2f aimpos;
	bool facingLeft = this.isFacingLeft();
	int teamNum = blob.getTeamNum();

	MediumshipInfo@ ship;
	if (!blob.get( "shipInfo", @ship )) 
	{ return; }
	
	//set engine burns to correct places

	CSpriteLayer@ upFire1		= this.getSpriteLayer(up_fire1);
	CSpriteLayer@ upFire2		= this.getSpriteLayer(up_fire2);
	CSpriteLayer@ downFire1		= this.getSpriteLayer(down_fire1);
	CSpriteLayer@ downFire2		= this.getSpriteLayer(down_fire2);
	CSpriteLayer@ leftFire1		= this.getSpriteLayer(left_fire1);
	CSpriteLayer@ leftFire2		= this.getSpriteLayer(left_fire2);
	CSpriteLayer@ rightFire1	= this.getSpriteLayer(right_fire1);
	CSpriteLayer@ rightFire2	= this.getSpriteLayer(right_fire2);

	bool mainEngine = ship.forward_thrust;
	bool secEngine = ship.backward_thrust;
	bool leftEngine = ship.port_thrust;
	bool leftFrontEngine = ship.portBow_thrust;
	bool leftBackEngine = ship.portQuarter_thrust;
	bool rightEngine = ship.starboard_thrust;
	bool rightFrontEngine = ship.starboardBow_thrust;
	bool rightBackEngine = ship.starboardQuarter_thrust;

	f32 leftFlipDegrees = facingLeft ? 180.0f : 0.0f;
	if (upFire1 !is null) //forward engines
	{
		upFire1.SetVisible(mainEngine);

		upFire1.ResetTransform();
		upFire1.ScaleBy(0.8f, 0.8f);
		upFire1.RotateBy(-90.0f + leftFlipDegrees, Vec2f_zero);
	}
	if (upFire2 !is null)
	{
		upFire2.SetVisible(mainEngine);

		upFire2.ResetTransform();
		upFire2.RotateBy(-90 + leftFlipDegrees, Vec2f_zero);
	}

	if (downFire1 !is null) //backwards engines
	{
		downFire1.SetVisible(secEngine);

		downFire1.ResetTransform();
		downFire1.ScaleBy(0.5f, 0.5f);
		downFire1.RotateBy(90 + leftFlipDegrees, Vec2f_zero);
	}
	if (downFire2 !is null)
	{
		downFire2.SetVisible(secEngine);

		downFire2.ResetTransform();
		downFire2.ScaleBy(0.5f, 0.5f);
		downFire2.RotateBy(90 + leftFlipDegrees, Vec2f_zero);
	}
	
	if (rightFire1 !is null)//left side engines
	{ rightFire1.SetVisible(leftEngine || leftFrontEngine); }
	if (rightFire2 !is null)
	{ rightFire2.SetVisible(leftEngine || leftBackEngine); }

	if (leftFire1 !is null)//right side engines
	{ leftFire1.SetVisible(rightEngine || rightFrontEngine); }
	if (leftFire2 !is null)
	{ leftFire2.SetVisible(rightEngine || rightBackEngine); }


	if (mainEngine)
	{
		Vec2f engineOffset = Vec2f(facingLeft ? 9.5f: -9.5f, 32.0f);
		engineOffset.RotateByDegrees(blobAngle);
		Vec2f trailPos = blobPos + engineOffset;

		makeEngineTrail(trailPos, 2, blobVel, blobAngle, teamNum);

		engineOffset = Vec2f(facingLeft ? -3.5f : 3.5f , 31.0f);
		engineOffset.RotateByDegrees(blobAngle);
		trailPos = blobPos + engineOffset;

		makeEngineTrail(trailPos, 4, blobVel, blobAngle, teamNum);
	}

}

void makeEngineTrail(Vec2f trailPos = Vec2f_zero, u8 particleNum = 0, Vec2f blobVel = Vec2f_zero, float blobAngle = 0.0f, int teamNum = 0)
{
	Vec2f trailNorm = Vec2f(0, 1.0f);
	trailNorm.RotateByDegrees(blobAngle);

	u32 gameTime = getGameTime();

	f32 trailSwing = Maths::Sin(gameTime * 0.1f);

	f32 swingMaxAngle = 30.0f * trailSwing;

	SColor color = getTeamColorWW(teamNum);

	for(int i = 0; i <= particleNum; i++) //will do particleNum + 1
    {
		u8 alpha = 200.0f + (55.0f * _martyr_anim_r.NextFloat()); //randomize alpha
		color.setAlpha(alpha);

		f32 pRatio = float(i) / float(particleNum);
		f32 pAngle = (pRatio*2.0f) - 1.0f;

		Vec2f pVel = trailNorm;
		pVel.RotateByDegrees(swingMaxAngle*pAngle);
		pVel *= 3.0f - Maths::Abs(pAngle);

		pVel += blobVel;

        CParticle@ p = ParticlePixelUnlimited(trailPos, pVel, color, true);
        if(p !is null)
        {
   	        p.collides = false;
   	        p.gravity = Vec2f_zero;
            p.bounce = 0;
            p.Z = 7;
            p.timeout = 30.0f + (15.0f * _martyr_anim_r.NextFloat());
			p.setRenderStyle(RenderStyle::light);
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
