#include "SpaceshipGlobal.as"
#include "SpaceshipVars.as"
#include "CommonFX.as"

void onInit( CBlob@ this )
{
	this.getShape().SetGravityScale(0.0f);
	this.getShape().getConsts().mapCollisions = false;

	this.set_bool("active", false);
	this.set_u32("ownerBlobID", 0);

	this.set_u8(soundEmitNumString, 0); //CommonFX.as
	this.set_bool(clientFirstTickString, true); //SpaceshipGlobal.as
}

void onInit( CSprite@ this )
{
	this.SetVisible(false);
}

void onTick( CSprite@ this )
{
	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null)
	{ return; }
	
	u32 ownerBlobID = thisBlob.get_u32("ownerBlobID");
	CBlob@ ownerBlob = getBlobByNetworkID(ownerBlobID);
	if (!thisBlob.isAttached() || ownerBlobID == 0 || ownerBlob == null) return;

	u8 soundEmitNum = thisBlob.get_u8(soundEmitNumString);

	if (thisBlob.get_bool(clientFirstTickString))
	{
		string filename = getEngineSoundFilename(soundEmitNum);
		this.SetEmitSound(filename + ".ogg");
		this.SetEmitSoundPaused(true);
		this.SetEmitSoundVolume(0);
		this.SetEmitSoundSpeed(0);
		thisBlob.set_bool(clientFirstTickString, false);
	}
	
	SpaceshipVars@ moveVars;
	if (!ownerBlob.get("moveVars", @moveVars)) return;
	
	Vec2f ownerBlobVel = ownerBlob.getVelocity();
	float ownerBlobSpeed = ownerBlobVel.getLength();

	switch(soundEmitNum)
	{
		case 0:
		{
			float volume = 0.0f;
			float speed = 1.0f;

			if (moveVars.forward_thrust)
			{
				volume += 1.1f;
				speed += 0.15;
			}
			if (moveVars.backward_thrust)
			{
				volume += 0.8f;
				speed += 0.1;
			}
			if (moveVars.port_thrust)
			{
				volume += 0.5f;
				speed += 0.1;
			}
			if (moveVars.starboard_thrust)
			{
				volume += 0.5f;
				speed += 0.1;
			}

			CBlob@ playerBlob = getLocalPlayerBlob();
			if (playerBlob != null && playerBlob !is ownerBlob)
			{
				Vec2f playerBlobPos = playerBlob.getPosition();
				Vec2f ownerBlobPos = ownerBlob.getPosition();
				Vec2f playerBlobVel = playerBlob.getVelocity();
				
				float dist = (playerBlobPos - ownerBlobPos).getLength();

				ownerBlobPos += ownerBlobVel;
				playerBlobPos += playerBlobVel;

				float newDist = (playerBlobPos - ownerBlobPos).getLength();

				float crunch = dist - newDist;
				speed += crunch*0.02f;
			}
			else
			{
				speed += (ownerBlobSpeed * 0.01f) - 0.05f;
			}

			this.SetEmitSoundPaused(volume <= 0.1f);
			this.SetEmitSoundVolume(volume);
			this.SetEmitSoundSpeed(speed);
		}
		break;

		case 1:
		{
			float volume = Maths::Min((ownerBlobSpeed * 0.5f)+0.35f, 2.5f);
			float speed = Maths::Max(0.2f + (volume*0.6f), 0.9f);

			if (ownerBlob.get_bool(isWarpBoolString)) speed = 2.0f;

			this.SetEmitSoundPaused(false);
			this.SetEmitSoundVolume(volume);
			this.SetEmitSoundSpeed(speed);
		}
		break;

		case 2:
		{
			float volume = 0.0f;
			float speed = 0.2f;

			if (moveVars.forward_thrust)
			{
				volume += 1.5f;
				speed += 0.15;
			}
			if (moveVars.backward_thrust)
			{
				volume += 1.0f;
				speed += 0.1;
			}
			if (moveVars.portBow_thrust || moveVars.port_thrust)
			{
				volume += 0.7f;
				speed += 0.1;
			}
			if (moveVars.starboardBow_thrust || moveVars.starboard_thrust)
			{
				volume += 0.7f;
				speed += 0.1;
			}

			this.SetEmitSoundPaused(volume <= 0.1f);
			this.SetEmitSoundVolume(volume);
			this.SetEmitSoundSpeed(speed);
		}
		break;
	}
}

void onTick( CBlob@ this )
{
	if (!isServer())
	{ return; }
	
	u32 ownerBlobID = this.get_u32("ownerBlobID");
	CBlob@ ownerBlob = getBlobByNetworkID(ownerBlobID);
	if (!this.isAttached() || ownerBlobID == 0 || ownerBlob == null)
	{
		this.server_Die();
	}
}

string getEngineSoundFilename( u8 soundEmitNum = 0 )
{
	string filename = "thruster_noise";

	switch(soundEmitNum)
	{
		case 0:
		{ filename = "thruster_noise"; }
		break;
		case 1:
		{ filename = "engine_loop"; }
		break;
		case 2:
		{ filename = "thruster_noise"; }
		break;
	}

	return filename;
}