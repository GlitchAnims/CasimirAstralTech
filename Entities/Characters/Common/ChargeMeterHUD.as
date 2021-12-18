#include "ChargeCommon.as"

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();

    if (blob.isMyPlayer())
    {
        GUI::DrawIcon("GUI/jslot.png", 1, Vec2f(32,32), Vec2f(2,48));//For the Charge meter script
        DrawChargeMeter(blob, Vec2f(52,56)); 
    }
}

void DrawChargeMeter(CBlob@ this, Vec2f origin)
{
    string manaFile = "GUI/ManaBar.png";
	int barLength = 4;
    int segmentWidth = 24;
    GUI::DrawIcon("GUI/jends.png", 0, Vec2f(8,16), origin+Vec2f(-8,0));

    s32 currCharge = this.get_s32(absoluteCharge_string);
    s32 maxCharge = this.get_s32(absoluteMaxCharge_string);
	
	f32 chargePerSegment = maxCharge/barLength;
	
	f32 fourthManaSeg = chargePerSegment*(1.0f/4.0f);
	f32 halfManaSeg = chargePerSegment*(1.0f/2.0f);
	f32 threeFourthsManaSeg = chargePerSegment*(3.0f/4.0f);
	
	int CHARGE = 0;
    for (int step = 0; step < barLength; step += 1)
    {
        GUI::DrawIcon("GUI/ManaBack.png", 0, Vec2f(12,16), origin+Vec2f(segmentWidth*CHARGE,0));
        f32 thisCHARGE = currCharge - step*chargePerSegment;
        if (thisCHARGE > 0)
        {
            Vec2f manapos = origin+Vec2f(segmentWidth*CHARGE-1,0);
            if (thisCHARGE <= fourthManaSeg) { GUI::DrawIcon(manaFile, 4, Vec2f(16,16), manapos); }
            else if (thisCHARGE <= halfManaSeg) { GUI::DrawIcon(manaFile, 3, Vec2f(16,16), manapos); }
            else if (thisCHARGE <= threeFourthsManaSeg) { GUI::DrawIcon(manaFile, 2, Vec2f(16,16), manapos); }
            else if (thisCHARGE > threeFourthsManaSeg) { GUI::DrawIcon(manaFile, 1, Vec2f(16,16), manapos); }
            else { GUI::DrawIcon(manaFile, 0, Vec2f(16,16), manapos); }
        }
        CHARGE++;
    }
    GUI::DrawIcon("GUI/jends.png", 1, Vec2f(8,16), origin+Vec2f(segmentWidth*CHARGE,0));
	GUI::DrawText(currCharge+"/"+maxCharge, origin+Vec2f(-42,8), color_white );
}