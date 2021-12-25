//Smallship Include

#include "SpaceshipGlobal.as"
#include "CommonFX.as"

class BallisticsOwnerInfo
{
	ComputerTargetInfo@[] tickInfo;
};

class ComputerTargetInfo
{
	// ship general
	Vec2f current_pos;
	Vec2f last_pos;
	Vec2f current_vel;
	Vec2f last_vel; 
	
	ComputerTargetInfo()
	{
		//ship general
		current_pos = Vec2f_zero;
		last_pos = Vec2f_zero;
		current_vel = Vec2f_zero;
		last_vel = Vec2f_zero;
	}
}

const SColor greenConsoleColor = SColor(200, 0, 255, 0);

void makeBlobTriangle( Vec2f blobPos = Vec2f_zero, f32 blobAngle = 0.0f, Vec2f scale = Vec2f(1.0f, 1.0f) )
{
	if (blobPos == Vec2f_zero)
	{ return; }

	Vec2f[] vertexPos =
	{
		Vec2f(1.0f, 0),
		Vec2f(-0.5f, -0.866f),
		Vec2f(-0.5f, 0.866f),
		Vec2f(1.0f, 0)
	};

	for(int i = 0; i < vertexPos.length(); i++)
	{
		vertexPos[i].x *= scale.x;
		vertexPos[i].y *= scale.y;
		vertexPos[i].RotateByDegrees(blobAngle);
		vertexPos[i] += blobPos;
	}

	for(int i = 0; i < (vertexPos.length() - 1); i++) 
	{
		Vec2f pos1 = vertexPos[i];
		Vec2f pos2 = vertexPos[i+1];

		drawParticleLine( pos1, pos2, Vec2f_zero, greenConsoleColor, 0, 2.0f);
	}
	
}




/*
{
	Vec2f fireVec = Vec2f(1.0f,0) * ship.shot_speed; 
	fireVec.RotateByDegrees(blobAngle); //shot vector
	fireVec += thisVel; //adds ship speed

	Vec2f pPos = firePos;

	SColor color = SColor(255, 255, 10, 10);
	for(int alpha = 255; alpha > 1; alpha -=3) //when alpha reaches 0, cut the loop
	{
		color.setAlpha(alpha);

		CParticle@ p = ParticlePixelUnlimited(pPos, Vec2f_zero, color, true);
		if(p !is null)
		{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 7;
			p.timeout = 0;
			p.setRenderStyle(RenderStyle::light);
		}

		pPos += fireVec * 0.1f; //update pos each step
	}
}
*/