//
//  ViewController.m
//  SpriteKitSimpleGame
//
//  Created by 王 巍 on 13-6-16.
//  Copyright (c) 2013年 王 巍. All rights reserved.
//

#import "ViewController.h"
#import "MyScene.h"
#import "ResultScene.h"

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    
    // Create and configure the scene.
    SKScene * scene = [MyScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];
}

#pragma mark - Rotation
- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
