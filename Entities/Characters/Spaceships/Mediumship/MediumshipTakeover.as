
#include "SpaceshipGlobal.as"
#include "CommonFX.as"
#include "GenericButtonCommon.as"
#include "ChargeCommon.as"

Random _mediumship_takeover_r(99766);

void onInit( CBlob@ this )
{
	AddIconToken("$takeover_ship_icon$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 0);
	AddIconToken("$quit_ship_icon$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 1);

	this.set_f32("takeover_blob_health", 0.0f);
	this.set_string("takeover_blob_name", "");

	this.addCommandID( takeover_command_ID );
	this.addCommandID( quit_ship_command_ID );
}

void onTick( CBlob@ this )
{
	if (!isClient())
	{ return; }

	if (this.getPlayer() != null)
	{ return; }
	
	Vec2f pPos = this.getPosition();

	u16 particleNum = 3;
	for (int i = 0; i < particleNum; i++)
    {
        Vec2f pVel(_mediumship_takeover_r.NextFloat() * 10.0f, 0);
        pVel.RotateBy(_mediumship_takeover_r.NextFloat() * 360.0f);

		u8 alpha = 255;
		u8 red = 200.0f + (50.0f * _mediumship_takeover_r.NextFloat());
		u8 green = 200.0f + (50.0f * _mediumship_takeover_r.NextFloat());
		u8 blue = 80.0f * _mediumship_takeover_r.NextFloat();

		SColor color = SColor(alpha, red, green, blue);
		
		CParticle@ p = ParticlePixelUnlimited(pPos, pVel, color, true);
        if(p !is null)
        {
            p.collides = false;
            p.gravity = Vec2f_zero;
            p.bounce = 0;
            p.Z = 200;
            p.timeout = 3.0f + (3.0f * _mediumship_takeover_r.NextFloat());
			p.damping = 0.8f;
        }
    }
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	//if (!canSeeButtons(this, caller)) return;

	if (caller is this)
	{
		caller.CreateGenericButton("$quit_ship_icon$", Vec2f(0, 16), this, this.getCommandID(quit_ship_command_ID), getTranslatedString("Exit ship"));
		return;
	}

	if (this.getPlayer() != null) //is there a player inside? return
	{ return; }

	int thisTeamNum = this.getTeamNum();
	int callerTeamNum = caller.getTeamNum();

	if (thisTeamNum != callerTeamNum)
	{ return; }

	if (caller.hasTag(smallTag)) //does not show button if not a smallship
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID()); //parasite blobID
		caller.CreateGenericButton("$takeover_ship_icon$", Vec2f(0, 8), this, this.getCommandID(takeover_command_ID), getTranslatedString("Takeover ship"), params);
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (this == null)
	{ return; }

	if (!isServer())
	{ return; }

    if (cmd == this.getCommandID(takeover_command_ID)) // 1 shot instance
    {
		if (this.getPlayer() != null)
		{ return; } //someone already in

		u16 parasiteID;
		if (!params.saferead_u16(parasiteID)) return;

		CBlob@ parasiteBlob = getBlobByNetworkID(parasiteID);
		if (parasiteID == 0 || parasiteBlob == null)
		{ return; }

		f32 parasiteHealth = parasiteBlob.getHealth();
		if (parasiteHealth <= 0)
		{ return; }

		string parasiteName = parasiteBlob.getName();

		CPlayer@ parasitePlayer = parasiteBlob.getPlayer();
		if (parasitePlayer == null)
		{ return; }
		
		this.set_f32("takeover_blob_health", parasiteHealth);
		this.set_string("takeover_blob_name", parasiteName);

		parasiteBlob.server_SetPlayer(null);
		this.server_SetPlayer(parasitePlayer);
		//parasiteBlob.set_bool(explosionFXBoolString, false);
		parasiteBlob.server_Die();
	}
	else if (cmd == this.getCommandID(quit_ship_command_ID))
	{
		CPlayer@ player = this.getPlayer();
		if (player == null || this == null)
		{ return; }

		f32 blobHealth = this.get_f32("takeover_blob_health"); //no health, no switch
		if (blobHealth <= 0)
		{ return; }
		
		this.server_SetPlayer(null);
		Vec2f exitPos = this.getPosition() + Vec2f(0,16);

		string blobName = this.get_string("takeover_blob_name");
		if (blobName.length() <= 0)
		{
			blobName = "fighter";
		}

		CBlob@ newBlob = server_CreateBlob(blobName, player.getTeamNum(), exitPos);
		if (newBlob != null)
		{
			newBlob.setVelocity(Vec2f(0,1));
			newBlob.IgnoreCollisionWhileOverlapped(this);
			newBlob.server_SetHealth(blobHealth);
			if (newBlob.exists("spawn immunity time"))
			{
				newBlob.set_u32("spawn immunity time", 0);
				//newBlob.Sync("spawn immunity time", true);
			}

			newBlob.server_SetPlayer(player);
		}
	}
}