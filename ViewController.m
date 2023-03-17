//
//  ViewController.m
//  AR 
//
//  Created by Kendall Toerner on 1/15/18.
//  Copyright © 2018 Kendall Toerner. All rights reserved.
//

#import "ViewController.h"
#import <SceneKit/SceneKitTypes.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <ARSCNViewDelegate, UIGestureRecognizerDelegate, SCNPhysicsContactDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;

@end

UIImageView *findsurfaceimage;
UIImageView *findsurfacehandimage;

UILabel *coordlabelx;
UILabel *coordlabely;
UILabel *coordlabelz;

UILabel *levellabel;
UILabel *portalslabel;
UILabel *timelabel;
UILabel *centerlabel;
UILabel *gameoverlabel;
UILabel *scorelabel;
UILabel *highscorelabel;
UILabel *introlabel;
UILabel *websitelabel;

UIButton *startgamebutton;
UIButton *pausebutton;

NSTimer *updateblocktimer;
NSTimer *leveltimer;
NSTimer *handanimationtimer;

AVAudioPlayer *sound_bgmusic;
AVAudioPlayer *sound_blockcharge;
AVAudioPlayer *sound_blocklaunch;
AVAudioPlayer *sound_portalclose;

UIImageView *warningview;

UIImageView *introview;
UIButton *actionbutton;

UIImageView *educationimage;

UIImageView *ingameui;

UIView *timehighlightview;

float insertionYOffset = 0.125;

//Cube size
float dimension = 0.08;

float mass = 0.1;

float blockholddistance = -0.5;

float floorplaneheight = 0;

int blocks = 0;

int level = 0;
int leveltime = 0;

float origx = 0;
float origy = 0;
float origz = 0;

float firsttouchx = 0;
float firsttouchy = 0;

int fullwidth;
int fullheight;

bool planefound = false;

bool newblockready = true;

bool introvisible = true;

bool educationimagevisible = false;

bool invalidateothertouches = false;

int portalsclosed = 0;

UIView *levelbanner;

NSMutableArray *block;
NSMutableArray *portal;
NSMutableArray *restrictedlist;

NSUserDefaults *defaults;

ARWorldTrackingConfiguration *configuration;

typedef NS_OPTIONS(NSUInteger, CollisionCategory)
{
    CollisionCategoryBottom  = 1 << 0,
    CollisionCategoryCube    = 1 << 1,
};

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupScene];
    [self setupLights];
    [self setupFallenObjectRemoval];
    [self setupRecognizers];
    
    //Setup sounds
    /*
    NSString *bgmusic = [NSString stringWithFormat:@"%@/bgmusic.m4a", [[NSBundle mainBundle] resourcePath]];
    sound_bgmusic = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:bgmusic] error:nil];
    sound_bgmusic.delegate = self;
    [sound_bgmusic prepareToPlay];
    [sound_bgmusic setNumberOfLoops:10000];
    [sound_bgmusic setVolume:1];
    [sound_bgmusic play];
     */
    
    /*
    [sound_bgmusic prepareToPlay];
    [sound_blockcharge prepareToPlay];
    [sound_blocklaunch prepareToPlay];
    [sound_portalclose prepareToPlay];
    */
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    fullwidth = self.view.frame.size.width;
    fullheight = self.view.frame.size.height;
    
    configuration = [ARWorldTrackingConfiguration new];
    
    block = [[NSMutableArray alloc] init];
    portal = [[NSMutableArray alloc] init];
    restrictedlist = [[NSMutableArray alloc] init];
    
    [UIApplication.sharedApplication setIdleTimerDisabled:YES];
    
    [self showWarning];
    [self showIntro];
    
    //[self getCameraPosition];
}

- (void)showIntro
{
    introview = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"splash.png"]];
    introview.frame = CGRectMake(0, 0, fullwidth, fullheight);
    [self.view addSubview:introview];
    
    //Game over label
    gameoverlabel = [[UILabel alloc] initWithFrame:CGRectMake(0, fullheight*.05, fullwidth, fullheight/5)];
    gameoverlabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:25];
    gameoverlabel.textColor = [UIColor colorWithWhite:1 alpha:1];
    gameoverlabel.textAlignment = NSTextAlignmentCenter;
    gameoverlabel.text = @"Game Over!";
    gameoverlabel.alpha = 0;
    [self.view addSubview:gameoverlabel];
    
    //Score label
    scorelabel = [[UILabel alloc] initWithFrame:CGRectMake(0, fullheight*.434, fullwidth, fullheight*.1)];
    scorelabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20];
    scorelabel.textColor = [UIColor colorWithWhite:1 alpha:1];
    scorelabel.textAlignment = NSTextAlignmentCenter;
    scorelabel.text = @"";
    scorelabel.alpha = 0;
    [self.view addSubview:scorelabel];
    
    //High score label
    highscorelabel = [[UILabel alloc] initWithFrame:CGRectMake(0, fullheight*0.52, fullwidth, fullheight*.1)];
    highscorelabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20];
    highscorelabel.textColor = [UIColor colorWithWhite:1 alpha:1];
    highscorelabel.textAlignment = NSTextAlignmentCenter;
    highscorelabel.text = [NSString stringWithFormat:@"High Score: Level %i",(int)[defaults integerForKey:@"levelrecord"]];
    highscorelabel.alpha = 0;
    [self.view addSubview:highscorelabel];
    
    //Tap to start new game
    startgamebutton = [[UIButton alloc] initWithFrame:CGRectMake(fullwidth*.25, fullheight*.5, fullwidth*.5, fullheight*.08)];
    [startgamebutton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15]];
    [startgamebutton setTitle:@"New Game" forState:UIControlStateNormal];
    [startgamebutton setTitleColor:[UIColor colorWithWhite:1 alpha:1] forState:UIControlStateNormal];
    [startgamebutton setTitleColor:[UIColor colorWithWhite:1 alpha:1] forState:UIControlStateSelected];
    startgamebutton.backgroundColor = [UIColor colorWithWhite:1 alpha:0];
    [startgamebutton.layer setBorderWidth:5];
    [startgamebutton.layer setBorderColor:(__bridge CGColorRef _Nullable)([UIColor whiteColor])];
    //startgamebutton.tintColor = [UIColor whiteColor];
    startgamebutton.alpha = 0;
    //[self.view addSubview:startgamebutton];
    
    //Intro label
    introlabel = [[UILabel alloc] initWithFrame:CGRectMake(0, fullheight*.52, fullwidth, fullheight/5)];
    introlabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13];
    introlabel.textColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1];
    introlabel.textAlignment = NSTextAlignmentCenter;
    //[self.view addSubview:introlabel];
    
    //Website label
    websitelabel = [[UILabel alloc] initWithFrame:CGRectMake(0, fullheight*.85, fullwidth, fullheight/5)];
    websitelabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13];
    websitelabel.textColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1];
    websitelabel.textAlignment = NSTextAlignmentCenter;
    websitelabel.text = @"www.kendalltoerner.com";
    //[self.view addSubview:websitelabel];
    
    //Action button
    actionbutton = [[UIButton alloc] initWithFrame:CGRectMake((fullwidth/2)-(fullwidth*.475/2)-1, fullheight*.677, fullwidth*.475, fullheight*.055)];
    [actionbutton setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
    [actionbutton addTarget:self action:@selector(actionbutton_down) forControlEvents:UIControlEventTouchDown];
    [actionbutton addTarget:self action:@selector(actionbutton_pressed) forControlEvents:UIControlEventTouchUpInside];
    actionbutton.alpha = 0;
    [self.view addSubview:actionbutton];
    
    introvisible = true;
    
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(beginARTracking) userInfo:nil repeats:false];
    
    [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(hideIntro) userInfo:nil repeats:false];
}

-(void)actionbutton_down
{
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        actionbutton.alpha = 0.4;
    }completion:nil];
}

-(void)actionbutton_pressed
{
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        actionbutton.alpha = 0;
    }completion:nil];
    
    [self newGame];
}

-(void)beginARTracking
{
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    configuration.lightEstimationEnabled = YES;
    [self.sceneView.session runWithConfiguration:configuration];
}

-(void)hideIntro
{
    introvisible = false;
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        introview.alpha = 0;
    }completion:nil];
}
     
- (void)setupScene
{
    //Setup the ARSCNViewDelegate - this gives us callbacks to handle newgeometry creation
    self.sceneView.delegate = self;
    
    //A dictionary of all the current planes and boxes being rendered in the scene
    self.planes = [NSMutableDictionary new];
    
    self.sceneView.showsStatistics = NO;
    
    //Turn on debug options to show the world origin and also render all of the feature points ARKit is tracking
    //self.sceneView.debugOptions = ARSCNDebugOptionShowWorldOrigin | ARSCNDebugOptionShowFeaturePoints;
    
    //Add this to see bounding geometry for physics interactions
    //SCNDebugOptionShowPhysicsShapes;
    
    SCNScene *scene = [SCNScene new];
    self.sceneView.scene = scene;
}

- (void)setupLights
{
    // Turn off all the default lights SceneKit adds since we are handling it ourselves
    self.sceneView.autoenablesDefaultLighting = NO;
    self.sceneView.automaticallyUpdatesLighting = NO;
    
    UIImage *env = [UIImage imageNamed: @"spherical.jpg"];
    self.sceneView.scene.lightingEnvironment.contents = env;
}

- (void)setupRecognizers
{
    //Single tap will insert a new piece of geometry into the scene
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    //[self.sceneView addGestureRecognizer:tapGestureRecognizer];
    
    //Press and hold will cause an explosion causing geometry in the local vicinity of the explosion to move
    UILongPressGestureRecognizer *explosionGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHoldFrom:)];
    explosionGestureRecognizer.minimumPressDuration = 0.5;
    //[self.sceneView addGestureRecognizer:explosionGestureRecognizer];
}

- (void)setupFallenObjectRemoval
{
    //Place killplane below world surface
    SCNBox *bottomPlane = [SCNBox boxWithWidth:10000 height:0.5 length:10000 chamferRadius:0];
    SCNMaterial *bottomMaterial = [SCNMaterial new];
    bottomMaterial.diffuse.contents = [UIColor colorWithWhite:1.0 alpha:0.0];
    bottomPlane.materials = @[bottomMaterial];
    SCNNode *bottomNode = [SCNNode nodeWithGeometry:bottomPlane];
    bottomNode.position = SCNVector3Make(0, -10, 0);
    bottomNode.physicsBody = [SCNPhysicsBody
                              bodyWithType:SCNPhysicsBodyTypeKinematic
                              shape: nil];
    bottomNode.physicsBody.categoryBitMask = CollisionCategoryBottom;
    bottomNode.physicsBody.contactTestBitMask = CollisionCategoryCube;
    [self.sceneView.scene.rootNode addChildNode:bottomNode];
    self.sceneView.scene.physicsWorld.contactDelegate = self;
}

-(void)showWarning
{
    //Find surface info graphic
    findsurfaceimage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"findsurface.png"]];
    findsurfaceimage.frame = CGRectMake(0, 0, fullwidth, fullheight);
    [self.view addSubview:findsurfaceimage];
    
    //Find surface hand graphic
    findsurfacehandimage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hand.png"]];
    findsurfacehandimage.frame = CGRectMake((fullwidth/2)-((580/4)/3), fullheight*0.75, 580/4, 808/4);
    [self.view addSubview:findsurfacehandimage];
    
    handanimationtimer = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(playHandAnimation) userInfo:nil repeats:true];
    
    //Level banner
    levelbanner = [[UIView alloc] initWithFrame:CGRectMake(0, fullheight*.25, 0, fullheight*.15)];
    levelbanner.backgroundColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1];
    levelbanner.alpha = 0;
    [self.view addSubview:levelbanner];
    
    //Center label
    centerlabel = [[UILabel alloc] initWithFrame:CGRectMake(-fullwidth, fullheight/4.5, fullwidth, fullheight/5)];
    centerlabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:35];
    centerlabel.textColor = [UIColor colorWithWhite:1 alpha:1];
    centerlabel.textAlignment = NSTextAlignmentCenter;
    centerlabel.text = @"";
    centerlabel.alpha = 0;
    [self.view addSubview:centerlabel];
    
    //Instructions graphic
    educationimage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"education.png"]];
    educationimage.frame = CGRectMake(0, 0, fullwidth, fullheight);
    educationimage.alpha = 0;
    [self.view addSubview:educationimage];
    
    //Warning view
    warningview = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"warning.png"]];
    warningview.frame = CGRectMake(0, 0, fullwidth, fullheight);
    //[self.view addSubview:warningview];
}

-(void)pausebutton_pressed
{
    if (educationimagevisible)
    {
        [self startLevelTimer];
        
        [pausebutton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
        [pausebutton setImage:[UIImage imageNamed:@"pause_pressed.png"] forState:UIControlStateHighlighted];
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            educationimage.alpha = 0;
        }completion:nil];
        
        educationimagevisible = false;
    }
    else
    {
        [self pauseLevelTimer];
        
        [pausebutton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
        [pausebutton setImage:[UIImage imageNamed:@"play_pressed.png"] forState:UIControlStateHighlighted];
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            educationimage.alpha = 1;
        }completion:nil];
        
        educationimagevisible = true;
    }
}

-(void)playHandAnimation
{
    [UIView animateWithDuration:2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        findsurfacehandimage.frame = CGRectMake((fullwidth/2)-(580/4)/3, fullheight*0.67, 580/4, 808/4);
    }completion:nil];
    
    [UIView animateWithDuration:2 delay:2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        findsurfacehandimage.frame = CGRectMake((fullwidth/2)-(580/4)/3, fullheight*0.75, 580/4, 808/4);
    }completion:nil];
}

-(void)endGame
{
    [self showScore];
    
    level = -1;
    
    //for (SCNNode *b in block) [b removeFromParentNode];
}

-(void)newGame
{
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        introview.alpha = 0;
        scorelabel.alpha = 0;
        highscorelabel.alpha = 0;
        actionbutton.alpha = 0;
        
        ingameui.alpha = 1;
        pausebutton.alpha = 1;
        timelabel.alpha = 1;
        levellabel.alpha = 1;
        portalslabel.alpha = 1;
    }completion:nil];
    
    introvisible = false;
    
    [self newLevel];
}

- (void)showScore
{
    introvisible = true;
    
    [scorelabel setText:[NSString stringWithFormat:@"Level %i",level-1]];
    [highscorelabel setText:[NSString stringWithFormat:@"Level %i",(int)[defaults integerForKey:@"levelrecord"]]];
    
    introlabel.frame = CGRectMake(0, fullheight*.82, fullwidth, fullheight/5);
    
    introview.image = [UIImage imageNamed:@"scorebg.png"];
    
    actionbutton.frame = CGRectMake((fullwidth/2)-(fullwidth*.475/2)-1, fullheight*.677, fullwidth*.475, fullheight*.055);
    
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        ingameui.alpha = 0;
        pausebutton.alpha = 0;
        timelabel.alpha = 0;
        levellabel.alpha = 0;
        portalslabel.alpha = 0;
    }completion:nil];
    
    [UIView animateWithDuration:0.25 delay:0.1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        actionbutton.alpha = 0.1;
        introview.alpha = 1;
        scorelabel.alpha = 1;
        highscorelabel.alpha = 1;
    }completion:nil];
}

-(void)newLevel
{
    if ((level) > [defaults integerForKey:@"levelrecord"]) [defaults setInteger:level forKey:@"levelrecord"];
    
    if ([defaults integerForKey:@"levelrecord"] < 1)
    {
        educationimagevisible = true;
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            educationimage.alpha = 1;
        }completion:nil];
    }
    
    level++;
    if (level == 1) [self newBlock];
    if (level == 0) level++;
    [levellabel setText:[NSString stringWithFormat:@"%i",level]];
    
    [centerlabel setText:[NSString stringWithFormat:@"Level %i",level]];
    
    if (!educationimagevisible) [self animateLevelBanner];
    
    [self generatePortals];
    
    leveltime = (int)portal.count*6;
    if (level > 2) leveltime = (int)portal.count*4;
    if (level > 3) leveltime = (int)portal.count*2;
    if (level > 5) leveltime = (int)portal.count+15;
    
    [timelabel setText:[NSString stringWithFormat:@"%i",leveltime]];
    
    if (educationimagevisible) return;
    [self startLevelTimer];
}

-(void)startLevelTimer
{
    [leveltimer invalidate];
    
    if (level > 0)
    {
        if (!leveltimer.valid)
        {
            if ([defaults integerForKey:@"levelrecord"] > 0)
            {
                leveltimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerTick) userInfo:nil repeats:true];
                
                timehighlightview.backgroundColor = [UIColor colorWithRed:0 green:0.8 blue:1 alpha:0.9];
                
                //Flash timer to show it started
                [UIView animateWithDuration:0.5 delay:1.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    timehighlightview.alpha = 1;
                }completion:nil];
                
                [UIView animateWithDuration:0.5 delay:2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    timehighlightview.alpha = 0;
                }completion:nil];
                
                [UIView animateWithDuration:0.5 delay:2.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    timehighlightview.alpha = 1;
                }completion:nil];
                
                [UIView animateWithDuration:0.5 delay:3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    timehighlightview.alpha = 0;
                }completion:nil];
            }
        }
    }
}

-(void)pauseLevelTimer
{
    [leveltimer invalidate];
}

-(void)animateLevelBanner
{
    centerlabel.alpha = 0;
    
    [UIView animateWithDuration:1.5 delay:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        centerlabel.alpha = 1;
        levelbanner.alpha = 1;
        levelbanner.frame = CGRectMake(0, fullheight*.25, fullwidth, fullheight*.15);
    }completion:nil];
    
    [UIView animateWithDuration:4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        centerlabel.frame = CGRectMake(fullwidth*.25, fullheight/4.5, fullwidth, fullheight/5);
    }completion:nil];
    
    [UIView animateWithDuration:1.5 delay:2.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        centerlabel.alpha = 0;
        levelbanner.alpha = 0;
        levelbanner.frame = CGRectMake(fullwidth, fullheight*.25, fullwidth, fullheight*.15);
    }completion:^(BOOL finished) {
        centerlabel.frame = CGRectMake(-fullwidth, fullheight/4.5, fullwidth, fullheight/5);
        levelbanner.frame = CGRectMake(0, fullheight*.25, 0, fullheight*.15);
    }];
}

-(void)timerTick
{
    leveltime--;
    [timelabel setText:[NSString stringWithFormat:@"%i",leveltime]];
    if ((leveltime < 11) && (leveltime > 0))
    {
        timehighlightview.backgroundColor = [UIColor colorWithRed:1 green:0.4 blue:0.4 alpha:0.9];
        
        //Flash timer to show time running out
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            timehighlightview.alpha = 1;
        }completion:nil];
        
        [UIView animateWithDuration:0.5 delay:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            timehighlightview.alpha = 0;
        }completion:nil];
    }
    if (leveltime == 0)
    {
        [leveltimer invalidate];
        [self endGame];
    }
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (introvisible) return;
    
    if (educationimagevisible)
    {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            educationimage.alpha = 0;
        }completion:nil];
        
        if (!([defaults integerForKey:@"levelrecord"] < 1)) [self startLevelTimer];
        
        [pausebutton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
        [pausebutton setImage:[UIImage imageNamed:@"pause_pressed.png"] forState:UIControlStateHighlighted];
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            educationimage.alpha = 0;
        }completion:nil];
        
        educationimagevisible = false;
    }
    
    if ((blocks < 1)) return;
    
    if (!newblockready) return;
    
    CGPoint location = [[touches anyObject] locationInView:self.view];
    firsttouchx = location.x;
    firsttouchy = location.y;
    
    SCNNode *current = block[blocks-1];
    NSMutableArray *seq = [[NSMutableArray alloc] init];
    [seq addObject:[SCNAction rotateByX:M_PI*.2 y:0 z:M_PI duration:0.7]];
    [seq addObject:[SCNAction rotateByX:M_PI*.2 y:0 z:M_PI duration:0.5]];
    [seq addObject:[SCNAction rotateByX:M_PI*.15 y:0 z:M_PI duration:0.4]];
    [seq addObject:[SCNAction rotateByX:M_PI*.125 y:0 z:M_PI duration:0.3]];
    [seq addObject:[SCNAction rotateByX:M_PI*.125 y:0 z:M_PI duration:0.2]];
    [seq addObject:[SCNAction rotateByX:M_PI*.125 y:0 z:M_PI duration:0.15]];
    [seq addObject:[SCNAction repeatActionForever:[SCNAction rotateByX:M_PI*.125 y:0 z:M_PI duration:0.1]]];
    
    [self particles:current];
    
    [current runAction:[SCNAction sequence:seq]];
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (introvisible) return;
    
    if (educationimagevisible) return;
    
    if (blocks < 1) return;
    
    if (!newblockready) return;
    
    if (level == -1) return;
    
    if (invalidateothertouches) return;
    
    //Get touch location on screen
    //CGPoint location = [[touches anyObject] locationInView:self.view];
    //float touch_x = (location.x-firsttouchx)/5000;
    //float touch_z = (location.y-firsttouchy)/5000;
    /*
    float x = (location.x-firsttouchx)*0.001;
    float z = (location.y-firsttouchy)*0.001;
     */
    
    //SCNNode *current = block[blocks-1];
    
    //[current runAction:[SCNAction rotateByX:touch_z*M_PI y:0 z:-touch_x*M_PI duration:0.01]];
    //current.position = SCNVector3Make(0, 0, -0.75);
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (introvisible) return;
    
    if (educationimagevisible) return;
    
    if (blocks < 1) return;
    
    if (!newblockready) return;
    
    if (level == -1) return;
    
    if (invalidateothertouches)
    {
        invalidateothertouches = false;
        return;
    }
    
    newblockready = false;
    
    [updateblocktimer invalidate];
    
    SCNNode *current = block[blocks-1];
    [current removeAllActions];
    //SCNNode *previous = block[blocks-2];
    current.physicsBody.affectedByGravity = true;
    SCNVector3 force = SCNVector3Make([self getCameraDirection].x*1.5, [self getCameraDirection].y*1.5, [self getCameraDirection].z*1.5);
    SCNVector3 pos = [self getCameraPosition];
    [current.physicsBody applyForce:force atPosition:pos impulse:true];
    
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(newBlock) userInfo:nil repeats:false];
}

-(void)showUI
{
    CGRect timehighlightview_frame = CGRectMake(fullwidth*.673, fullheight*.0105, fullwidth*.31, fullheight*.065);
    CGRect ingameuiframe = CGRectMake(0, fullheight*.003, fullwidth, fullwidth*.145);
    
    CGRect leveltextframe = CGRectMake(0, 0, fullwidth*.34, fullheight*.1);
    CGRect portalstextframe = CGRectMake(fullwidth*.33, 0, fullwidth*.33, fullheight*.1);
    CGRect timetextframe = CGRectMake(fullwidth*.66, 0, fullwidth*.33, fullheight*.1);
    
    timehighlightview = [[UIView alloc] initWithFrame:timehighlightview_frame];
    timehighlightview.backgroundColor = [UIColor colorWithRed:0 green:.8 blue:1 alpha:.92];
    timehighlightview.alpha = 0;
    [self.view addSubview:timehighlightview];
    
    ingameui = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ingameui.png"]];
    ingameui.frame = ingameuiframe;
    [self.view addSubview:ingameui];
    
    levellabel = [[UILabel alloc] initWithFrame:leveltextframe];
    levellabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
    levellabel.textColor = [UIColor colorWithWhite:1 alpha:1];
    levellabel.textAlignment = NSTextAlignmentCenter;
    levellabel.text = @"0";
    [self.view addSubview:levellabel];
    
    portalslabel = [[UILabel alloc] initWithFrame:portalstextframe];
    portalslabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
    portalslabel.textColor = [UIColor colorWithWhite:1 alpha:1];
    portalslabel.textAlignment = NSTextAlignmentCenter;
    portalslabel.text = @"0";
    [self.view addSubview:portalslabel];
    
    timelabel = [[UILabel alloc] initWithFrame:timetextframe];
    timelabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
    timelabel.textColor = [UIColor colorWithWhite:1 alpha:1];
    timelabel.textAlignment = NSTextAlignmentCenter;
    timelabel.text = @"0";
    [self.view addSubview:timelabel];
    
    //Pause button/instruction recall
    pausebutton = [[UIButton alloc] initWithFrame:CGRectMake(fullwidth*0.87, fullheight*.09, fullwidth*.1, fullwidth*.1)];
    [pausebutton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
    [pausebutton setImage:[UIImage imageNamed:@"pause_pressed.png"] forState:UIControlStateHighlighted];
    [pausebutton addTarget:self action:@selector(pausebutton_pressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pausebutton];
}

-(SCNVector3)getCameraDirection
{
    ARFrame *frame = self.sceneView.session.currentFrame;
    SCNMatrix4 mat = SCNMatrix4FromMat4(frame.camera.transform);
    SCNVector3 dir = SCNVector3Make(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33);
    //SCNVector3 pos = SCNVector3Make(mat.m41, mat.m42, mat.m43);
    return dir;
}

-(SCNVector3)getCameraPosition
{
    ARFrame *frame = self.sceneView.session.currentFrame;
    SCNMatrix4 mat = SCNMatrix4FromMat4(frame.camera.transform);
    //SCNVector3 dir = SCNVector3Make(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33);
    SCNVector3 pos = SCNVector3Make(mat.m41, mat.m42, mat.m43);
    return pos;
}

-(void)particles:(SCNNode*)node
{
    SCNParticleSystem *exp = [[SCNParticleSystem alloc] init];
    exp.emitterShape = node.geometry;
    exp.loops = true;
    exp.birthRate = 1000;
    exp.emissionDuration = 0.05;
    exp.spreadingAngle = 180;
    //exp.birthDirection = SCNParticleBirthDirectionRandom;
    exp.particleDiesOnCollision = true;
    exp.particleLifeSpan = 0.1;
    exp.particleLifeSpanVariation = 0.05;
    exp.particleVelocity = 0.1;
    exp.particleVelocityVariation = 0.1;
    exp.particleSize = 0.0004;
    //exp.stretchFactor = 0.05;
    exp.particleColor = [UIColor colorWithRed:0.8 green:.8 blue:1 alpha:1];
    [node addParticleSystem:exp];
}

-(void)particleExplosion:(SCNNode*)node
{
    SCNParticleSystem *exp = [[SCNParticleSystem alloc] init];
    exp.emitterShape = node.geometry;
    exp.loops = false;
    exp.birthRate = 3000;
    exp.emissionDuration = 0.0005;
    exp.spreadingAngle = 180;
    //exp.birthDirection = SCNParticleBirthDirectionRandom;
    exp.particleDiesOnCollision = false;
    exp.particleLifeSpan = 2.5;
    exp.particleLifeSpanVariation = 2;
    exp.particleVelocity = 2.5;
    exp.particleVelocityVariation = 0.1;
    exp.particleSize = 0.001;
    //exp.stretchFactor = 0.05;
    exp.particleColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
    [node addParticleSystem:exp];
}

/*
-(void)particleExplosion:(SCNNode*)node
{
    SCNParticleSystem *exp = [[SCNParticleSystem alloc] init];
    exp.emitterShape = node.geometry;
    exp.loops = false;
    exp.birthRate = 6000;
    exp.emissionDuration = 0.25;
    exp.spreadingAngle = 180;
    //exp.birthDirection = SCNParticleBirthDirectionRandom;
    exp.particleDiesOnCollision = false;
    exp.particleLifeSpan = 3;
    exp.particleLifeSpanVariation = 0.05;
    exp.particleVelocity = 2;
    exp.particleVelocityVariation = 0.01;
    exp.particleSize = 0.0025;
    //exp.stretchFactor = 0.05;
    exp.particleColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
    [node addParticleSystem:exp];
}
 */

-(void)generatePortals
{
    //[restrictedlist removeAllObjects];
    for (SCNNode *p in portal)
    {
        for (SCNNode *child in p.childNodes)
        {
            [child removeAllActions];
            [child removeAllParticleSystems];
            [child removeFromParentNode];
        }
        [p removeAllActions];
        [p removeAllParticleSystems];
        [p removeFromParentNode];
    }
    
    [portal removeAllObjects];
    portalsclosed = 0;
    
    for (int i = 0; i < level*3; i++)
    {
        //SCNSphere *geometry = [SCNSphere sphereWithRadius:dimension*3.5];
        SCNCylinder *geometry = [SCNCylinder cylinderWithRadius:dimension*3.5 height:dimension/2];
        
        //geometry.firstMaterial = [self setMaterialWithDiffuse:@"diffuse_steel.png" roughness:@"roughness_steel.png" metalness:@"metal_steel.png" normal:@"normal_steel.png"];
        geometry.firstMaterial.diffuse.contents = [UIImage imageNamed:@"Portal1.png"];
        geometry.firstMaterial.transparency = 0.65;
        SCNNode *cyl = [SCNNode nodeWithGeometry:geometry];
        
        //float duration = 1.5;
        /*
        SCNAction *animatedPortal = [SCNAction customActionWithDuration:duration actionBlock:^(SCNNode * _Nonnull node, CGFloat elapsedTime) {
            int num = elapsedTime*10;
            NSString *texturename = [NSString stringWithFormat:@"Portal%d.png",num];
            UIImage *texture = [UIImage imageNamed:texturename];
            cyl.geometry.firstMaterial.diffuse.contents = texture;
        }];
         */
        
        //[cyl runAction:[SCNAction repeatActionForever:animatedPortal]];
        
        SCNNode *node = [[SCNNode alloc] init];
        
        SCNLookAtConstraint *look = [SCNLookAtConstraint lookAtConstraintWithTarget:self.sceneView.pointOfView];
        look.gimbalLockEnabled = true;
        NSMutableArray *constraint = [[NSMutableArray alloc] init];
        [constraint addObject:look];
        node.constraints = constraint;
        
        //The physicsBody tells SceneKit this geometry should be manipulated by the physics engine
        cyl.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeStatic shape:nil];
        cyl.physicsBody.categoryBitMask = CollisionCategoryCube;
        cyl.physicsBody.contactTestBitMask = CollisionCategoryCube;
        cyl.physicsBody.affectedByGravity = false;
        
        //node.name = [NSString stringWithFormat:@"%i",blocks];
        
        SCNVector3 pos = [self getCameraPosition];
        
        float scale = 0.085;
        
        node.position = SCNVector3Make(pos.x + [self newNeutralRandom:scale], pos.y + [self newNeutralRandom:scale]/3, pos.z + [self newNeutralRandom:scale]);
        
        SCNParticleSystem *exp = [[SCNParticleSystem alloc] init];
        exp.emitterShape = cyl.geometry;
        exp.loops = true;
        exp.birthRate = 1000/level;
        exp.emissionDuration = 0.05;
        exp.spreadingAngle = 180;
        //exp.birthDirection = SCNParticleBirthDirectionRandom;
        exp.particleDiesOnCollision = true;
        exp.particleLifeSpan = 0.1;
        exp.particleLifeSpanVariation = 0.05;
        exp.particleVelocity = 0.1;
        exp.particleVelocityVariation = 0.1;
        exp.particleSize = 0.001;
        exp.particleColor = [UIColor colorWithRed:0 green:.7 blue:1 alpha:1];
        [cyl addParticleSystem:exp];
        
        [node addChildNode:cyl];
        [node.childNodes[0] runAction:[SCNAction rotateByX:M_PI/2 y:0 z:0 duration:0]];
        
        [self.sceneView.scene.rootNode addChildNode:node];
        
        [portal addObject:node];
    }
    
    [portalslabel setText:[NSString stringWithFormat:@"%lu",(unsigned long)portal.count]];
}

-(float)newRandom:(float)scale
{
    float ran2 = 0;
    
    while ((ran2 > -18) && (ran2 < 18))
    {
        float ran = arc4random()%10;
        //ran2 = ((ran - 4.5) * 10);
        ran2 = (ran * 5);
    }
    
    return ran2*scale;
}

-(float)newNeutralRandom:(float)scale
{
    float ran2 = 0;
    
    while ((ran2 > -18) && (ran2 < 18))
    {
        float ran = arc4random()%10;
        ran2 = ((ran - 4.5) * 10);
    }
    
    return ran2*scale;
}

-(void)updateBlock
{
    SCNNode *current = block[blocks-1];
    //current.position = SCNVector3Make(0, 0, blockholddistance);
    //SCNVector3 pos = [self getCameraPosition];
    //[current runAction:[SCNAction moveTo:SCNVector3Make(0, 0, blockholddistance) duration:0.5]];
    current.position = SCNVector3Make(0, 0, blockholddistance);
}

- (void)handleTapFrom: (UITapGestureRecognizer *)recognizer
{
    if (blocks > 0) return;
    
    //Take the screen space tap coordinates and pass them to the hitTest method on the ARSCNView instance
    CGPoint tapPoint = [recognizer locationInView:self.sceneView];
    
    NSArray<ARHitTestResult *> *result = [self.sceneView hitTest:tapPoint types:ARHitTestResultTypeExistingPlaneUsingExtent];
    
    //If the intersection ray passes through any plane geometry they will be returned, with the planes ordered by distance from the camera
    if (result.count == 0) return;
    
    //If there are multiple hits, just pick the closest plane
    ARHitTestResult * hitResult = [result firstObject];
    [self newBlock:hitResult];
    
    recognizer.cancelsTouchesInView = false;
}

- (void)handleHoldFrom: (UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan) return;
    
    //Do something when user holds down
}

-(void)stopDetectingPlanes
{
    //Stop detecting new planes or updating existing ones.
    ARWorldTrackingConfiguration *configuration = (ARWorldTrackingConfiguration *)self.sceneView.session.configuration;
    configuration.planeDetection = ARPlaneDetectionNone;
    [self.sceneView.session runWithConfiguration:configuration];
}

- (void)handleHidePlaneFrom: (UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan) return;
    
    //Hide all the planes
    for(NSUUID *planeId in self.planes) [self.planes[planeId] hide];
    
    //Stop detecting new planes or updating existing ones.
    ARWorldTrackingConfiguration *configuration = (ARWorldTrackingConfiguration *)self.sceneView.session.configuration;
    configuration.planeDetection = ARPlaneDetectionNone;
    [self.sceneView.session runWithConfiguration:configuration];
}

- (void)newBlock
{
    blocks++;
    
    newblockready = true;
    
    //Import geometry
    SCNScene *logo = [SCNScene sceneNamed:@"art.scnassets/disc.dae"];
    SCNNode *node = [logo.rootNode childNodeWithName:@"disc" recursively:true];
    
    //Import geometry's animation
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"art.scnassets/disc" withExtension:@"dae"];
    SCNSceneSource *sceneSource = [SCNSceneSource sceneSourceWithURL:url options:nil];
    CAAnimation *anim = [sceneSource entryWithIdentifier:@"pCylinder1-anim" withClass:CAAnimation.class];
    anim.repeatCount = INFINITY;
    anim.speed = 50;
    [node addAnimation:anim forKey:@"anim"];
    
    //Scale geometry
    [node setScale:SCNVector3Make(0.1, 0.01, 0.1)];
    
    //Add new block at first block coordinate above last block height
    SCNBox *geometry = [SCNBox boxWithWidth:dimension height:dimension length:dimension chamferRadius:0.007];
    geometry.chamferSegmentCount= 10;
    geometry.firstMaterial = [self setMaterialWithDiffuse:@"g.png" roughness:@"roughness_steel.png" metalness:@"metal_steel.png" normal:@"normal_steel.png"];
    geometry.firstMaterial.transparency = 0.9;
    //SCNNode *node = [SCNNode nodeWithGeometry:geometry];
    
    //The physicsBody tells SceneKit this geometry should be manipulated by the physics engine
    node.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:nil];
    node.physicsBody.mass = mass;
    node.physicsBody.categoryBitMask = CollisionCategoryCube;
    node.physicsBody.contactTestBitMask = CollisionCategoryCube;
    node.physicsBody.affectedByGravity = false;
    
    float ran = arc4random()%10;
    ran = ran/100;
    
    //node.position = SCNVector3Make(ran, blocks * insertionYOffset, ran);
    node.name = [NSString stringWithFormat:@"%i",blocks];
    
    node.position = SCNVector3Make(0, 0, blockholddistance);
    //Slowly rotate block forever
    //[node runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:M_PI*.8 y:0 z:M_PI duration:2]]];
    [self.sceneView.pointOfView addChildNode:node];
    
    updateblocktimer = [NSTimer scheduledTimerWithTimeInterval:0.005 target:self selector:@selector(updateBlock) userInfo:nil repeats:true];
    /*
    node.position = SCNVector3Make(((SCNNode*)block[0]).position.x + ran, -0.5 + (blocks * insertionYOffset), ((SCNNode*)block[0]).position.z + ran);
    node.name = [NSString stringWithFormat:@"%i",blocks];
    [self.sceneView.scene.rootNode addChildNode:node];
     */
    [block addObject:node];
    
    //Save coordinates of current block as reference for moving it
    origx = node.rotation.x;
    origy = node.rotation.y;
    origz = node.rotation.z;
    /*
    origx = node.position.x;
    origy = blocks * insertionYOffset;
    origz = node.position.z;
     */
}

- (void)newBlock:(ARHitTestResult *)hitResult
{
    //Custom geometry
    /*
     SCNScene *scene = [SCNScene sceneNamed:@"geo.dae"];
     SCNNode *geometry = scene.rootNode.childNodes[0];
     SCNGeometry *geo = [SCNGeometry g]
     */
    
    //Place starting block if game not started
    if (blocks < 1)
    {
        blocks++;
        
        SCNBox *geometry = [SCNBox boxWithWidth:dimension height:dimension length:dimension chamferRadius:0.003];
        geometry.firstMaterial = [self setMaterialWithDiffuse:@"g.png" roughness:@"roughness_steel.png" metalness:@"metal_steel.png" normal:@"normal_steel.png"];
        SCNNode *node = [SCNNode nodeWithGeometry:geometry];
        
        //The physicsBody tells SceneKit this geometry should be manipulated by the physics engine
        node.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:nil];
        node.physicsBody.mass = mass;
        node.physicsBody.categoryBitMask = CollisionCategoryCube;
        node.physicsBody.contactTestBitMask = CollisionCategoryCube;
        
        //Insert the geometry slightly above the point the user tapped, so that it drops onto the plane using the physics engine
        float insertionVertOffset = .4;
        node.position = SCNVector3Make(hitResult.worldTransform.columns[3].x, hitResult.worldTransform.columns[3].y + insertionVertOffset, hitResult.worldTransform.columns[3].z);
        [self insertSpotLight: SCNVector3Make(hitResult.worldTransform.columns[3].x, hitResult.worldTransform.columns[3].y + (insertionVertOffset*25), hitResult.worldTransform.columns[3].z)];
        [self.sceneView.scene.rootNode addChildNode:node];
        [block addObject:node];
    }
    
    //[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(newBlock) userInfo:nil repeats:false];
}

- (void)insertSpotLight:(SCNVector3)position
{
    SCNLight *spotLight = [SCNLight light];
    spotLight.type = SCNLightTypeSpot;
    spotLight.spotInnerAngle = 90;
    spotLight.spotOuterAngle = 90;
    spotLight.castsShadow = true;
    spotLight.intensity = 500;
    spotLight.orthographicScale = 5;
    spotLight.color = [UIColor colorWithWhite:0.7 alpha:1];
    //spotLight.shadowColor = [UIColor colorWithWhite:0 alpha:1];
    //spotLight.zFar = 0.05;
    //spotLight.zNear = 0.001;
    SCNNode *spotNode = [SCNNode new];
    spotNode.light = spotLight;
    spotNode.position = position;
    // By default the stop light points directly down the negative
    // z-axis, we want to shine it down so rotate 90deg around the
    // x-axis to point it down
    spotNode.eulerAngles = SCNVector3Make(-M_PI / 1.8, 0, 0);
    [self.sceneView.scene.rootNode addChildNode: spotNode];
    
    [self insertAmbientLight:position];
}

-(void)insertAmbientLight:(SCNVector3)position
{
    SCNLight *spotLight = [SCNLight light];
    spotLight.type = SCNLightTypeAmbient;
    spotLight.castsShadow = true;
    spotLight.intensity = 7;
    spotLight.orthographicScale = 2;
    SCNNode *spotNode = [SCNNode new];
    spotNode.light = spotLight;
    //spotNode.position = position;
    // By default the stop light points directly down the negative
    // z-axis, we want to shine it down so rotate 90deg around the
    // x-axis to point it down
    spotNode.eulerAngles = SCNVector3Make(-M_PI / 1.7, 0, 0);
    [self.sceneView.scene.rootNode addChildNode: spotNode];
}

-(SCNMaterial*)setMaterialWithDiffuse:(NSString*)diffuse_imgname roughness:(NSString*)roughness_imgname metalness:(NSString*)metalness_imgname normal:(NSString*)normal_imgname
{
    SCNMaterial *mat = [SCNMaterial new];
    mat.lightingModelName = SCNLightingModelPhysicallyBased;
    mat.diffuse.contents = [UIImage imageNamed:diffuse_imgname];
    mat.roughness.contents = [UIImage imageNamed:roughness_imgname];
    mat.metalness.contents = [UIImage imageNamed:metalness_imgname];
    mat.normal.contents = [UIImage imageNamed:normal_imgname];
    return mat;
}

#pragma mark - SCNPhysicsContactDelegate

- (void)physicsWorld:(SCNPhysicsWorld *)world didBeginContact:(SCNPhysicsContact *)contact
{
    //Detect collision for kill plane
    CollisionCategory contactMask = contact.nodeA.physicsBody.categoryBitMask | contact.nodeB.physicsBody.categoryBitMask;
    
    if (contactMask == (CollisionCategoryBottom | CollisionCategoryCube))
    {
        if (contact.nodeA.physicsBody.categoryBitMask == CollisionCategoryBottom) [contact.nodeB removeFromParentNode];
        else [contact.nodeA removeFromParentNode];
    }
    else if ((contact.nodeA == block[blocks-1]) || (contact.nodeB == block[blocks-1]))
    {
        for (SCNNode *banned in restrictedlist) if ((contact.nodeA == banned) || (contact.nodeB == banned)) return;
        [restrictedlist addObject:contact.nodeA];
        [restrictedlist addObject:contact.nodeB];
        
        if (contact.nodeA == block[blocks-1])
        {
            [contact.nodeA removeFromParentNode];
            //contact.nodeA.geometry.firstMaterial = [self setMaterialWithDiffuse:@"diffuse_steel_bal.png" roughness:@"roughness_steel.png" metalness:@"metal_steel.png" normal:@"normal_steel.png"];
            contact.nodeB.particleSystems[0].particleColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
            [contact.nodeB runAction:[SCNAction scaleTo:0 duration:0.5]];
            
            [self particleExplosion:contact.nodeB];
            
            portalsclosed++;
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSTimer scheduledTimerWithTimeInterval:.55 target:self selector:@selector(removePortal:) userInfo:contact.nodeB repeats:false];
                
                [portalslabel setText:[NSString stringWithFormat:@"%lu",portal.count-portalsclosed]];
                if (portalsclosed >= portal.count) [NSTimer scheduledTimerWithTimeInterval:0.51 target:self selector:@selector(newLevel) userInfo:nil repeats:false];
            });
        }
        else
        {
            [contact.nodeB removeFromParentNode];
            //contact.nodeB.geometry.firstMaterial = [self setMaterialWithDiffuse:@"diffuse_steel_bal.png" roughness:@"roughness_steel.png" metalness:@"metal_steel.png" normal:@"normal_steel.png"];
            contact.nodeA.particleSystems[0].particleColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
            [contact.nodeA runAction:[SCNAction scaleTo:0 duration:0.5]];
            
            [self particleExplosion:contact.nodeA];
            
            portalsclosed++;
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSTimer scheduledTimerWithTimeInterval:.55 target:self selector:@selector(removePortal:) userInfo:contact.nodeA repeats:false];
                
                [portalslabel setText:[NSString stringWithFormat:@"%lu",portal.count-portalsclosed]];
                if (portalsclosed >= portal.count) [NSTimer scheduledTimerWithTimeInterval:0.51 target:self selector:@selector(newLevel) userInfo:nil repeats:false];
            });
        }
    }
}

-(void)removePortal:(NSTimer*)timer
{
    SCNNode *portal = (SCNNode*)[timer userInfo];
    for (SCNNode *child in portal.childNodes)
    {
        [child removeAllActions];
        [child removeAllParticleSystems];
        [child removeFromParentNode];
    }
    [portal removeAllActions];
    [portal removeAllParticleSystems];
    [portal removeFromParentNode];
}

#pragma mark - ARSCNViewDelegate

- (void)renderer:(id <SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time
{
    ARLightEstimate *estimate = self.sceneView.session.currentFrame.lightEstimate;
    
    if (!estimate) return;
    
    CGFloat intensity = estimate.ambientIntensity / 1000.0;
    self.sceneView.scene.lightingEnvironment.intensity = intensity;
}

/**
 Implement this to provide a custom node for the given anchor.
 
 @discussion This node will automatically be added to the scene graph.
 If this method is not implemented, a node will be automatically created.
 If nil is returned the anchor will be ignored.
 @param renderer The renderer that will render the scene.
 @param anchor The added anchor.
 @return Node that will be mapped to the anchor or nil.
 */
//- (nullable SCNNode *)renderer:(id <SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
//  return nil;
//}

/**
 Called when a new node has been mapped to the given anchor.
 
 @param renderer The renderer that will render the scene.
 @param node The node that maps to the anchor.
 @param anchor The added anchor.
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    if (![anchor isKindOfClass:[ARPlaneAnchor class]]) return;
    
    // When a new plane is detected we create a new SceneKit plane to visualize it in 3D
    
    Plane *plane = [[Plane alloc] initWithAnchor: (ARPlaneAnchor *)anchor isHidden: YES];
    [self.planes setObject:plane forKey:anchor.identifier];
    [node addChildNode:plane];
    
    floorplaneheight = plane.position.y;
    
    SCNNode *txtnode = [self.sceneView.pointOfView childNodeWithName:@"textnode" recursively:true];
    
    if (!planefound)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.7 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                findsurfaceimage.alpha = 0;
                findsurfacehandimage.alpha = 0;
            }completion:nil];
            
            [handanimationtimer invalidate];
            
            [self showUI];
            
            [self newLevel];
        });
        
        SCNVector3 trans = SCNVector3Make(0, 22, 0);
        [txtnode runAction:[SCNAction moveBy:trans duration:2]];
        //[txtnode runAction: [SCNAction repeatActionForever: [SCNAction rotateByX:0 y:0 z:2*M_PI duration:3]]];
        
        [self stopDetectingPlanes];
        //[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(stopDetectingPlanes) userInfo:nil repeats:false];
    }
    
    planefound = true;
}

/**
 Called when a node has been updated with data from the given anchor.
 
 @param renderer The renderer that will render the scene.
 @param node The node that was updated.
 @param anchor The anchor that was updated.
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    Plane *plane = [self.planes objectForKey:anchor.identifier];
    if (plane == nil) return;
    
    //Update 3D geometry when anchor changes (update plane)
    [plane update:(ARPlaneAnchor *)anchor];
}

/**
 Called when a mapped node has been removed from the scene graph for the given anchor.
 
 @param renderer The renderer that will render the scene.
 @param node The node that was removed.
 @param anchor The anchor that was removed.
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    //Nodes will be removed if planes multiple individual planes that are detected to all be part of a larger plane are merged.
    [self.planes removeObjectForKey:anchor.identifier];
}

/**
 Called when a node will be updated with data from the given anchor.
 
 @param renderer The renderer that will render the scene.
 @param node The node that will be updated.
 @param anchor The anchor that was updated.
 */
- (void)renderer:(id <SCNSceneRenderer>)renderer willUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    
}

- (void)session:(ARSession *)session didFailWithError:(NSError *)error
{
    // Present an error message to the user
}

- (void)sessionWasInterrupted:(ARSession *)session
{
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
}

- (void)sessionInterruptionEnded:(ARSession *)session
{
    // Reset tracking and/or remove existing anchors if consistent tracking is required
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.sceneView.session pause];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end

