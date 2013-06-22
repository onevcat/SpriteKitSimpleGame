//
//  MyScene.m
//  SpriteKitSimpleGame
//
//  Created by 王 巍 on 13-6-16.
//  Copyright (c) 2013年 王 巍. All rights reserved.
//

#import "MyScene.h"
#import <Foundation/NSObjCRuntime.h>
#import <AVFoundation/AVFoundation.h>
#import "ResultScene.h"

@interface MyScene()
@property (nonatomic, strong) NSMutableArray *monsters;
@property (nonatomic, strong) NSMutableArray *projectiles;

@property (nonatomic, strong) AVAudioPlayer *bgmPlayer;
@property (nonatomic, strong) SKAction *projectileSoundEffectAction;

@property (nonatomic, assign) int monstersDestroyed;
@end

@implementation MyScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        NSString *bgmPath = [[NSBundle mainBundle] pathForResource:@"background-music-aac" ofType:@"caf"];
        self.bgmPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:bgmPath] error:NULL];
        self.bgmPlayer.numberOfLoops = -1;
        [self.bgmPlayer play];
        
        self.projectileSoundEffectAction = [SKAction playSoundFileNamed:@"pew-pew-lei.caf" waitForCompletion:NO];
        
        self.monsters = [NSMutableArray array];
        self.projectiles = [NSMutableArray array];
        
        //1 Set background color for this scene
        self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        
        //2 Create a new sprite
        SKSpriteNode *player = [SKSpriteNode spriteNodeWithImageNamed:@"player"];

        //3 Set it's position to the center right edge of screen
        player.position = CGPointMake(player.size.width/2, size.height/2);
        
        //4 Add it to current scene
        [self addChild:player];

        //5 Repeat add monster to the scene every 1 second.
        SKAction *actionAddMonster = [SKAction runBlock:^{
            [self addMonster];
        }];
        SKAction *actionWaitNextMonster = [SKAction waitForDuration:1];
        [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[actionAddMonster,actionWaitNextMonster]]]];
    }

    return self;
}

- (void) addMonster {
    SKSpriteNode *monster = [SKSpriteNode spriteNodeWithImageNamed:@"monster"];
    
    //1 Determine where to spawn the monster along the Y axis
    CGSize winSize = self.size;
    int minY = monster.size.height / 2;
    int maxY = winSize.height - monster.size.height/2;
    int rangeY = maxY - minY;
    int actualY = (arc4random() % rangeY) + minY;

    //2 Create the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    monster.position = CGPointMake(winSize.width + monster.size.width/2, actualY);
    [self addChild:monster];
    
    //3 Determine speed of the monster
    int minDuration = 2.0;
    int maxDuration = 4.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    
    //4 Create the actions. Move monster sprite across the screen and remove it from scene after finished.
    SKAction *actionMove = [SKAction moveTo:CGPointMake(-monster.size.width/2, actualY)
                                   duration:actualDuration];
    SKAction *actionMoveDone = [SKAction runBlock:^{
        [monster removeFromParent];
        [self.monsters removeObject:monster];
        [self changeToResultSceneWithWon:NO];
        //TODO: Show a lose scene
    }];
    [monster runAction:[SKAction sequence:@[actionMove,actionMoveDone]]];
    
    [self.monsters addObject:monster];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        //1 Set up initial location of projectile
        CGSize winSize = self.size;
        SKSpriteNode *projectile = [SKSpriteNode spriteNodeWithImageNamed:@"projectile.png"];
        projectile.position = CGPointMake(projectile.size.width/2, winSize.height/2);
        
        //2 Get the touch location tn the scene and calculate offset
        CGPoint location = [touch locationInNode:self];
        CGPoint offset = CGPointMake(location.x - projectile.position.x, location.y - projectile.position.y);
        
        // Bail out if you are shooting down or backwards
        if (offset.x <= 0) return;
        // Ok to add now - we've double checked position
        [self addChild:projectile];
        
        int realX = winSize.width + (projectile.size.width/2);
        float ratio = (float) offset.y / (float) offset.x;
        int realY = (realX * ratio) + projectile.position.y;
        CGPoint realDest = CGPointMake(realX, realY);
        
        //3 Determine the length of how far you're shooting
        int offRealX = realX - projectile.position.x;
        int offRealY = realY - projectile.position.y;
        float length = sqrtf((offRealX*offRealX)+(offRealY*offRealY));
        float velocity = self.size.width/1; // projectile speed. 
        float realMoveDuration = length/velocity;
        
        //4 Move projectile to actual endpoint and play the throw sound effect
        SKAction *moveAction = [SKAction moveTo:realDest duration:realMoveDuration];
        SKAction *projectileCastAction = [SKAction group:@[moveAction,self.projectileSoundEffectAction]];
        [projectile runAction:projectileCastAction completion:^{
            [projectile removeFromParent];
            [self.projectiles removeObject:projectile];
        }];
        
        [self.projectiles addObject:projectile];
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    NSMutableArray *projectilesToDelete = [[NSMutableArray alloc] init];
    for (SKSpriteNode *projectile in self.projectiles) {
        
        NSMutableArray *monstersToDelete = [[NSMutableArray alloc] init];
        for (SKSpriteNode *monster in self.monsters) {
            
            if (CGRectIntersectsRect(projectile.frame, monster.frame)) {
                [monstersToDelete addObject:monster];
            }
        }
        
        for (SKSpriteNode *monster in monstersToDelete) {
            [self.monsters removeObject:monster];
            [monster removeFromParent];
            
            self.monstersDestroyed++;
            if (self.monstersDestroyed >= 30) {
                [self changeToResultSceneWithWon:YES];
            }
        }
        
        if (monstersToDelete.count > 0) {
            [projectilesToDelete addObject:projectile];
        }
    }
    
    for (SKSpriteNode *projectile in projectilesToDelete) {
        [self.projectiles removeObject:projectile];
        [projectile removeFromParent];
    }
}

-(void) changeToResultSceneWithWon:(BOOL)won
{
    [self.bgmPlayer stop];
    self.bgmPlayer = nil;
    ResultScene *rs = [[ResultScene alloc] initWithSize:self.size won:won];
    SKTransition *reveal = [SKTransition revealWithDirection:SKTransitionDirectionUp duration:1.0];
    [self.scene.view presentScene:rs transition:reveal];
}

@end
