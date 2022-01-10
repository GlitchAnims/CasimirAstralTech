//Smallship Include

#include "SpaceshipGlobal.as"
#include "CommonFX.as"

const string hasNavCompString = "has_nav_comp";
const string hasBallisticsString = "has_ballistics";
const string hasTargetingString = "has_targeting";

const string targetingTimerString = "targeting_timer";
const string currentTargetIDString = "current_target_ID";
const string interferenceMultString = "interference_mult";

const f32 maxPosInterference = 32.0f;
const f32 maxVelInterference = 3.0f;
const f32 maxAngleInterference = 30.0f;
const f32 maxAimPosInterference = 64.0f;

Random _computer_logic_r(53991);

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

class ComputerBlobInfo
{
	Vec2f current_pos;
	Vec2f current_vel;
	int team_num;
	f32 blob_angle;
	f32 interference_mult;
	Vec2f current_aimpos;
	
	ComputerBlobInfo()
	{
		current_pos = Vec2f_zero;
		current_vel = Vec2f_zero;
		team_num = 0;
		blob_angle = 0;
		interference_mult = 0.0f;
		current_aimpos = Vec2f_zero;
	}
}

void makeBlobTriangle( Vec2f blobPos = Vec2f_zero, f32 blobAngle = 0.0f, Vec2f scale = Vec2f(1.0f, 1.0f), f32 particleStepDistance = 2.0f, SColor color = greenConsoleColor )
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

		drawParticleLine( pos1, pos2, Vec2f_zero, color, 0, particleStepDistance);
	}
	
}

void makeTargetSquare( Vec2f blobPos = Vec2f_zero, f32 blobAngle = 0.0f, Vec2f scale = Vec2f(1.0f, 1.0f), f32 cornerSeparation = 1.0f, f32 particleStepDistance = 2.0f, SColor color = greenConsoleColor)
{
	if (blobPos == Vec2f_zero)
	{ return; }

	Vec2f[] vertexPos =
	{
		Vec2f(1.0f, 0.0), 		//			O
		Vec2f(1.0f, 1.0), 		//			|
		Vec2f(0.0f, 1.0) 		//		O---O
	};

	for(int i = 0; i < vertexPos.length(); i++)
	{
		vertexPos[i].x *= scale.x;
		vertexPos[i].y *= scale.y;
		//vertexPos[i] += blobPos;
	}

	Vec2f separationVec = Vec2f(cornerSeparation, cornerSeparation);
	for(u8 corner = 0; corner < 4; corner++) //4 corners
	{
		for(uint vertex = 0; vertex < (vertexPos.length() - 1); vertex++) 
		{
			Vec2f pos1 = vertexPos[vertex];
			Vec2f pos2 = vertexPos[vertex+1];

			pos1 += separationVec;
			pos2 += separationVec;

			pos1.RotateByDegrees((90*corner) + blobAngle);
			pos2.RotateByDegrees((90*corner) + blobAngle);

			drawParticleLine( pos1 + blobPos, pos2 + blobPos, Vec2f_zero, color, 0, particleStepDistance);
		}
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