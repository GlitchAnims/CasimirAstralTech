void onInit( CBlob@ this )
{
    this.set_bool("shifting", false);
    this.set_bool("wheel_button", false);

    this.addCommandID("shiftpress");
    this.addCommandID("wheelpress");
    this.addCommandID("client_pos_sync");
}

void onTick( CBlob@ this )
{
    if (isServer())
	{
		u32 gameTime = getGameTime();
		u16 thisNetID = this.getNetworkID();

		if ((gameTime + thisNetID) % 30 == 0 && this.getPlayer() != null) // once a second, must have player
		{
            updatePosToClients( this );
		}
	}

    if (!this.isMyPlayer()) { return; }

    CControls@ controls = getControls();
    CBitStream params;

    if (controls.isKeyPressed(KEY_LSHIFT))
    {
        if(!this.get_bool("shifting"))
        {
            params.write_bool(true);
            this.SendCommand(this.getCommandID("shiftpress"), params);
            this.set_bool("shifting", true);
        }
    }
    else
    {
        if(this.get_bool("shifting"))
        {
            params.write_bool(false);
            this.SendCommand(this.getCommandID("shiftpress"), params);
            this.set_bool("shifting", false);
        }
    }

    CBitStream params2;
    if (controls.isKeyPressed( KEY_MBUTTON ))
    {
        if(!this.get_bool("wheel_button"))
        {
            params2.write_bool(true);
            this.SendCommand(this.getCommandID("wheelpress"), params2);
            this.set_bool("wheel_button", true);
        }
    }
    else
    {
        if(this.get_bool("wheel_button"))
        {
            params2.write_bool(false);
            this.SendCommand(this.getCommandID("wheelpress"), params2);
            this.set_bool("wheel_button", false);
        }
    }
}

void updatePosToClients( CBlob@ this )
{
    CBitStream params;

    params.write_Vec2f(this.getPosition());
    params.write_Vec2f(this.getVelocity());
    params.write_f32(this.getAngleDegrees());

    this.SendCommand(this.getCommandID("client_pos_sync"), params);
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (this == null) return;
    if (this.isMyPlayer()) return;
    
    if (cmd == this.getCommandID("shiftpress"))
    {
        bool isShifting = false;
        if (!params.saferead_bool(isShifting)) return;
        this.set_bool("shifting", isShifting);
    }
    else if (cmd == this.getCommandID("wheelpress"))
    {
        bool isWheelButton = false;
        if (!params.saferead_bool(isWheelButton)) return;
        this.set_bool("wheel_button", isWheelButton);
    }
    else if ( isClient() && cmd == this.getCommandID("client_pos_sync") )
    {
        Vec2f thisPos = Vec2f_zero;
        Vec2f thisVel = Vec2f_zero;
        float thisAngle = 0.0f;

        if (params.saferead_Vec2f(thisPos) && params.saferead_Vec2f(thisVel) && params.saferead_f32(thisAngle))
        {
            this.setPosition(thisPos);
            this.setVelocity(thisVel);
            this.setAngleDegrees(thisAngle);
        }
    }
    
}