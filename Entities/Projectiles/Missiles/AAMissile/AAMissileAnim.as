// Fighter animations

#include "SmallshipCommon.as";
#include "RunnerAnimCommon.as";
#include "RunnerCommon.as";
#include "KnockedCommon.as";
#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "CommonFX.as"

const string up_fire = "forward_burn";
const string down_fire = "backward_burn";
const string left_fire = "port_burn";
const string right_fire = "starboard_burn";

Random _fighter_anim_r(14861);

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

	// add engine burns
	this.RemoveSpriteLayer(up_fire);
	this.RemoveSpriteLayer(down_fire);
	this.RemoveSpriteLayer(left_fire);
	this.RemoveSpriteLayer(right_fire);
	CSpriteLayer@ upFire = this.addSpriteLayer(up_fire, "ThrustFlash.png", 27, 27);
	CSpriteLayer@ downFire = this.addSpriteLayer(down_fire, "ThrustFlash.png", 27, 27);
	CSpriteLayer@ leftFire = this.addSpriteLayer(left_fire, "ThrustFlash.png", 27, 27);
	CSpriteLayer@ rightFire = this.addSpriteLayer(right_fire, "ThrustFlash.png", 27, 27);
	if (upFire !is null)
	{
		Animation@ anim = upFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		upFire.SetVisible(false);
		upFire.SetRelativeZ(-1.1f);
		//upFire.RotateBy(0, Vec2f_zero);
		upFire.SetOffset(Vec2f(8, 0));
	}
	if (downFire !is null)
	{
		Animation@ anim = downFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		downFire.SetVisible(false);
		downFire.SetRelativeZ(-1.2f);
		downFire.ScaleBy(0.5f, 0.5f);
		downFire.RotateBy(180, Vec2f_zero);
		downFire.SetOffset(Vec2f(-6, 0));
	}
	if (leftFire !is null)
	{
		Animation@ anim = leftFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		leftFire.SetVisible(false);
		leftFire.SetRelativeZ(-1.3f);
		leftFire.ScaleBy(0.3f, 0.3f);
		leftFire.RotateBy(270, Vec2f_zero);
		leftFire.SetOffset(Vec2f(0, 5));
	}
	if (rightFire !is null)
	{
		Animation@ anim = rightFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		rightFire.SetVisible(false);
		rightFire.SetRelativeZ(-1.4f);
		rightFire.ScaleBy(0.3f, 0.3f);
		rightFire.RotateBy(90, Vec2f_zero);
		rightFire.SetOffset(Vec2f(0, -5));
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

	/*KnightInfo@ knight;
	if (!blob.get("knightInfo", @knight))
	{
		return;
	}*/

	SmallshipInfo@ ship;
	if (!blob.get( "shipInfo", @ship )) 
	{ return; }
	
	//set engine burns to correct visibility

	CSpriteLayer@ upFire	= this.getSpriteLayer(up_fire);
	CSpriteLayer@ downFire	= this.getSpriteLayer(down_fire);
	CSpriteLayer@ leftFire	= this.getSpriteLayer(left_fire);
	CSpriteLayer@ rightFire	= this.getSpriteLayer(right_fire);

	bool mainEngine = ship.forward_thrust;
	if (upFire !is null)
	{ upFire.SetVisible(mainEngine); }
	if (downFire !is null)
	{ downFire.SetVisible(ship.backward_thrust); }
	if (leftFire !is null)
	{ leftFire.SetVisible(ship.port_thrust); }
	if (rightFire !is null)
	{ rightFire.SetVisible(ship.starboard_thrust); }



	if (mainEngine)
	{
		Vec2f engineOffset = Vec2f(-8.0f, 0);
		engineOffset.RotateByDegrees(blobAngle);
		Vec2f trailPos = blobPos + engineOffset;

		Vec2f trailNorm = Vec2f(-1.0f, 0);
		trailNorm.RotateByDegrees(blobAngle);

		u32 gameTime = getGameTime();

		//f32 trailSwing = Maths::Sin(gameTime * 0.1f) + 1.0f;
		//trailSwing *= 0.5f;
		f32 trailSwing = Maths::Sin(gameTime * 0.1f);

		f32 swingMaxAngle = 30.0f * trailSwing;

		u16 particleNum = 9; //loop will do this + 1

		int teamNum = blob.getTeamNum();
		SColor color = getTeamColorWW(teamNum);

		for(int i = 0; i <= particleNum; i++)
	    {
			u8 alpha = 200.0f + (55.0f * _fighter_anim_r.NextFloat()); //randomize alpha
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
	            p.timeout = 30.0f + (15.0f * _fighter_anim_r.NextFloat());
				p.setRenderStyle(RenderStyle::light);
	    	}
		}
	}


	//set the head anim
	/*
	if (knocked)
	{
		blob.Tag("dead head");
	}
	else if (blob.isKeyPressed(key_action1))
	{
		blob.Tag("attack head");
		blob.Untag("dead head");
	}
	else
	{
		blob.Untag("attack head");
		blob.Untag("dead head");
	}*/

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
