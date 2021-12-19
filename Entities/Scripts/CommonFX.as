#include "TeamColour.as"

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