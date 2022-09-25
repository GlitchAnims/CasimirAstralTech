const string forwardFire1Name = "forward_fire1";
const string forwardFire2Name = "forward_fire2";
const string backwardFire1Name = "backward_fire1";
const string backwardFire2Name = "backward_fire2";
const string portFire1Name = "port_fire1";
const string portFire2Name = "port_fire2";
const string starboardFire1Name = "starboard_fire1";
const string starboardFire2Name = "starboard_fire2";

const string thrusterAnimation1Name = "normalFlash";
const string thrusterAnimation2Name = "strongFlash";

const string thrustFlashFilename = "ThrustFlashAll.png";
const Vec2f thrustFlashFrameSize = Vec2f(33.0f, 17.0f);

const string warpThrustAnimBoolString = "warp_thrust_anim";
const string boostAnimBoolString = "boost_anim";

const int[] thrustFrames1 = {0, 1, 2, 3};
const int[] thrustFrames2 = {4, 5, 6, 7};
const int[] thrustFrames3 = {8, 9, 10, 11};

Random _ship_anim_r(65444);

/*

	For Sprite Layers, the offset has the X value inverted, but not the Y value.


	X O O
	O o O
	O O O

	=

	Vec2f (1, -1);
	

*/
