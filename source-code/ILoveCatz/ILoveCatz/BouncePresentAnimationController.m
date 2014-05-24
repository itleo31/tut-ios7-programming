//
//  BouncePresentAnimationController.m
//  ILoveCatz
//
//  Created by kpham9 on 5/24/14.
//  Copyright (c) 2014 com.razeware. All rights reserved.
//

#import "BouncePresentAnimationController.h"

@implementation BouncePresentAnimationController

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // Obtain state from the context
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    CGRect finalFrame = [transitionContext finalFrameForViewController:toViewController];
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    // Obtain the container view
    UIView *containerView = [transitionContext containerView];
    
    // Set initial state
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    toViewController.view.frame = CGRectOffset(finalFrame, 0, screenBounds.size.height);
    
    // Add the view
    [containerView addSubview:toViewController.view];
    
    // Animate
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^{
        fromViewController.view.alpha = 0.5;
        toViewController.view.frame = finalFrame;
    } completion:^(BOOL finished) {
        fromViewController.view.alpha = 1;
        [transitionContext completeTransition:YES];
    }];
}

@end
