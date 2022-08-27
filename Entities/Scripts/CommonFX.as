#include "TeamColour.as"

const f32 simplePi = 3.1415f;
const f32 radianConversion = (Maths::Pi/180);

const SColor greenConsoleColor = SColor(200, 0, 255, 0);
const SColor redConsoleColor = SColor(200, 255, 20, 20);
const SColor yellowConsoleColor = SColor(200, 255, 255, 0);

Random _sprk_r2(12432);
void makeManaDrainParticles( Vec2f pPos, int amount )
{
	if ( !isClient() )
	return;
	
	for (int i = 0; i < amount; i++)
    {
        Vec2f pVel(_sprk_r2.NextFloat() * 7.0f, 0);
        pVel.RotateBy(_sprk_r2.NextFloat() * 360.0f);
		
		CParticle@ p = ParticlePixelUnlimited(pPos, pVel, SColor( 255, 120+XORRandom(40), 0, 255), true);
        if(p !is null)
        {
            p.collides = false;
            p.gravity = Vec2f_zero;
            p.bounce = 0;
            p.Z = 200;
            p.timeout = 10 + _sprk_r2.NextRanged(30);
			p.scale = 1.0f + _sprk_r2.NextFloat();
			p.damping = 0.8f;
        }
    }
}

void makeHullHitSparks( Vec2f pPos, int amount )
{
	if ( !isClient() )
	return;
	
	for (int i = 0; i < amount; i++)
    {
        Vec2f pVel(_sprk_r2.NextFloat() * 7.0f, 0);
        pVel.RotateBy(_sprk_r2.NextFloat() * 360.0f);

		u8 alpha = 255;
		u8 red = 200.0f + (50.0f * _sprk_r2.NextFloat());
		u8 green = 200.0f + (50.0f * _sprk_r2.NextFloat());
		u8 blue = 80.0f * _sprk_r2.NextFloat();

		SColor color = SColor(alpha, red, green, blue);
		
		CParticle@ p = ParticlePixelUnlimited(pPos, pVel, color, true);
        if(p !is null)
        {
            p.collides = false;
            p.gravity = Vec2f_zero;
            p.bounce = 0;
            p.Z = 200;
            p.timeout = 3.0f + (3.0f * _sprk_r2.NextFloat());
			p.damping = 0.8f;
        }
    }
}

void makeEnergyLink(Vec2f fromPos = Vec2f_zero, Vec2f toPos = Vec2f_zero, int teamNum = 0)
{
	if (!isClient())
	{ return; }
	u32 gameTime = getGameTime();

	Vec2f rayVec = toPos - fromPos;
	int steps = rayVec.getLength();

	Vec2f rayNorm = rayVec;
	rayNorm.Normalize();

	Vec2f rayDeviation = rayNorm;
	rayDeviation.RotateByDegrees(90);
	rayDeviation *= 4.0f; //perpendicular particle deviation

	SColor color = getTeamColor(teamNum);

	for(int i = 0; i < steps; i++) //particle loop
	{
		f32 chance = _sprk_r2.NextFloat(); //chance to not spawn particle
		if (chance > 0.3f)
		{ continue; }

		f32 waveTravel = i - gameTime; //forward and backwards wave travel
		f32 sinInput = waveTravel * 0.2f;
		f32 stepDeviation = Maths::Sin(sinInput); //particle deviation multiplier

		if (i < 8)
		{
			f32 deviationReduction = float(i) / 8.0f;
			stepDeviation *= deviationReduction;
		}
		if (i > (steps - 8))
		{
			f32 deviationReduction = -1.0f * ((float(i) - float(steps)) / 8.0f);
			stepDeviation *= deviationReduction;
		}

		Vec2f finalRayDeviation = rayDeviation * stepDeviation;

		Vec2f pPos = (rayNorm * i) + finalRayDeviation;
		pPos += fromPos;

    	CParticle@ p = ParticlePixelUnlimited(pPos, Vec2f_zero, color, true);
    	if(p !is null)
    	{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 8;
			p.timeout = 2;
		}
	}
}

void makeTeamAura(Vec2f auraCenter = Vec2f_zero, int teamNum = 0, Vec2f auraVel = Vec2f_zero, u16 particleNum = 20, f32 radius = 64.0f)
{
	SColor color = getTeamColor(teamNum);
	for(int i = 0; i < particleNum; i++)
	{
		u8 alpha = 40 + (170.0f * _sprk_r2.NextFloat()); //randomize alpha
		color.setAlpha(alpha);

		f32 randomDeviation = (i*0.3f) * _sprk_r2.NextFloat(); //random pixel deviation
		Vec2f prePos = Vec2f(radius - randomDeviation, 0); //distance
		prePos.RotateByDegrees(360.0f * _sprk_r2.NextFloat()); //random 360 rotation

		Vec2f pPos = auraCenter + prePos;
		Vec2f pGrav = -prePos * 0.005f; //particle gravity

		Vec2f pVel = prePos;
		pVel.Normalize();
		pVel *= 2.0f;
		pVel += auraVel;

		CParticle@ p = ParticlePixelUnlimited(pPos, pVel, color, true);
		if(p !is null)
		{
			p.collides = false;
			p.gravity = pGrav;
			p.bounce = 0;
			p.Z = 7;
			p.timeout = 12;
			p.setRenderStyle(RenderStyle::light);
		}
	}
}

SColor getTeamColorWW( int teamNum = -1, SColor color = SColor(255, 255, 0, 0) )
{
    switch (teamNum)
		{
			case 0: //blue
			{	
				color = SColor(255, 30, 30, 255);
			}
			break;

			case 1: //red
			{	
				color = SColor(255, 255, 0, 0);
			}
			break;
			case 2: //green
			{	
				color = SColor(255, 0, 200, 0);
			}
			break;
            case 3: //violet
			{	
				color = SColor(255, 255, 0, 255);
			}
			break;

			default:
			{	
				color = SColor(255, 255, 255, 255);
			}
		}
    
    return color;
}

void drawParticleLine( Vec2f pos1 = Vec2f_zero, Vec2f pos2 = Vec2f_zero, Vec2f pVel = Vec2f_zero, SColor color = SColor(255, 255, 255, 255), u8 timeout = 0, f32 pixelStagger = 1.0f)
{
	Vec2f lineVec = pos2 - pos1;
	Vec2f lineNorm = lineVec;
	lineNorm.Normalize();

	f32 lineLength = lineVec.getLength();

	for(f32 i = 0; i < lineLength; i += pixelStagger) 
	{
		Vec2f pPos = (lineNorm * i) + pos1;

		CParticle@ p = ParticlePixelUnlimited(pPos, pVel, color, true);
		if(p !is null)
		{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 7;
			p.timeout = timeout;
			p.setRenderStyle(RenderStyle::light);
		}
	}
}

void drawParticleCircle( Vec2f circlePos = Vec2f_zero, f32 radius = 0, Vec2f pVel = Vec2f_zero, SColor color = SColor(255, 255, 255, 255), u8 timeout = 0, f32 pixelStagger = 1.0f)
{
	radius = Maths::Max(radius, 4.0f);

	f32 circumference = (radius*2) * simplePi;
	f32 degreesPerStep = 360.0f / circumference;

	for(f32 i = 0; i < circumference; i += pixelStagger) 
	{
		Vec2f circleDeviation = Vec2f(1.0f, 0) * radius;
		circleDeviation.RotateByDegrees(degreesPerStep*i);
		Vec2f pPos = circleDeviation + circlePos;

		CParticle@ p = ParticlePixelUnlimited(pPos, pVel, color, true);
		if(p !is null)
		{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 7;
			p.timeout = timeout;
			p.setRenderStyle(RenderStyle::light);
		}
	}
}
void drawParticlePartialCircle( Vec2f circlePos = Vec2f_zero, f32 radius = 0, f32 percentage = 1.0f, f32 angle = 0.0f, SColor color = SColor(255, 255, 255, 255), u8 timeout = 0, f32 pixelStagger = 1.0f)
{
	if (percentage == 0 || percentage > 1 || percentage < -1)
	{
		print ("invalid circle percentage");
		return;
	}

	radius = Maths::Max(radius, 4.0f);

	f32 circumference = (radius*2) * simplePi;
	f32 degreesPerStep = 360.0f / circumference;

	if (percentage < 0) //invert
	{
		degreesPerStep *= -1.0f;
	}

	f32 totalCircumference = circumference * Maths::Abs(percentage);

	for(f32 i = 0; i < totalCircumference; i += pixelStagger) 
	{
		Vec2f circleDeviation = Vec2f(radius, 0);
		circleDeviation.RotateByDegrees((degreesPerStep*i) + angle);
		Vec2f pPos = circleDeviation + circlePos;

		CParticle@ p = ParticlePixelUnlimited(pPos, Vec2f_zero, color, true);
		if(p !is null)
		{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = 7;
			p.timeout = timeout;
			p.setRenderStyle(RenderStyle::light);
		}
	}
}

void makePodCarryAura( Vec2f auraCenter = Vec2f_zero, int teamNum = 0, Vec2f auraVel = Vec2f_zero, float pixelStagger = 1.0f, float waveSpan = 40.0f, f32 radius = 10.0f )
{
	SColor color = getTeamColor(teamNum);
	u32 gameTime = getGameTime();
	float rotationSpeed = gameTime * 8.0f;

	f32 circumference = (radius*2) * simplePi;
	f32 degreesPerStep = 360.0f / circumference;
	float midWave = Maths::FMod(rotationSpeed, 360.0f);
	
	for(f32 i = 0; i < circumference; i += pixelStagger) 
	{
		Vec2f circleDeviation = Vec2f((1.0f * radius) + _sprk_r2.NextFloat(), 0);
		float pAngle = degreesPerStep*i;

		f32 angleDiff = pAngle - midWave;
		angleDiff += angleDiff > 180 ? -360 : angleDiff < -180 ? 360 : 0;
		angleDiff = Maths::Abs(angleDiff);
		if (angleDiff < waveSpan)
		{
			f32 sinInput = (waveSpan - angleDiff) / waveSpan;
			f32 stepDeviation = (Maths::Sin(sinInput * simplePi * 0.5f) * 0.2f) + 1.0f; //particle deviation multiplier
			circleDeviation *= stepDeviation;
		}
		
		circleDeviation.RotateByDegrees(pAngle);

		Vec2f pPos = auraCenter + circleDeviation;
		Vec2f pVel = auraVel;

		u8 alpha = 100.0f * _sprk_r2.NextFloat(); //randomize alpha
		color.setAlpha(alpha);

		CParticle@ p = ParticlePixelUnlimited(pPos, pVel, color, true);
		if(p !is null)
		{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = -7;
			p.timeout = 2;
			p.setRenderStyle(RenderStyle::light);
		}
	}
}

void genericShipExplosion( Vec2f pos , int particleNum)
{
	if(!isClient())
	{return;}

	Sound::Play("GenericExplosion1.ogg", pos, 0.8f, 0.8f + XORRandom(10)/10.0f);

	for (int i = 0; i < particleNum; i++)
    {
        Vec2f vel(_sprk_r2.NextFloat() * 3.0f, 0);
        vel.RotateBy(_sprk_r2.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated("GenericBlast6.png", 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.5f, 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if(p is null) continue; //bail if we stop getting particles
		
    	p.fastcollision = true;
        p.damping = 0.85f;
		p.Z = 200.0f;
		p.lighting = false;
    }
}