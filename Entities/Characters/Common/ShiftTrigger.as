void onInit( CBlob@ this )
{
    this.addCommandID("shiftpress");
    this.addCommandID("negentropy");
}

void onTick( CBlob@ this )
{
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
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (this == null)
	{ return; }

    if (cmd == this.getCommandID("shiftpress"))
    {
        bool isShifting = false;
        if (!params.saferead_bool(isShifting)) return;
        this.set_bool("shifting", isShifting);
    }
}