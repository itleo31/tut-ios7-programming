//
//  ShrinkDismissAnimationController.m
//  ILoveCatz
//
//  Created by kpham9 on 5/24/14.
//  Copyright (c) 2014 com.razeware. All rights reserved.
//

#import "ShrinkDismissAnimationController.h"

@implementation ShrinkDismissAnimationController

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // Obtain state from the context
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    CGRect finalFrame = [transitionContext finalFrameForViewController:toViewController];
    UIView *containerView = [transitionContext containerView];
    
    // Set initial state
    toViewController.view.frame = finalFrame;
    toViewController.view.alpha = 0.5;
    
    // Add the view
    [containerView addSubview:toViewController.view];
    [containerView sendSubviewToBack:toViewController.view];
    
    // Animation
    // Create a snapshot
    UIView *intermediateView = [fromViewController.view snapshotViewAfterScreenUpdates:NO];
    intermediateView.frame = fromViewController.view.frame;
    [containerView addSubview:intermediateView];
    
    // Remove the real view
    [fromViewController.view removeFromSuperview];
    
    // Determine the intermediate and final frame for the from view
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect shrunkenFrame = CGRectInset(screenBounds, fromViewController.view.frame.size.width / 4, fromViewController.view.frame.size.height / 4);
    CGRect fromFinalFrame = CGRectOffset(shrunkenFrame, 0, screenBounds.size.height);
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    // Animate with keyframes
    [UIView animateKeyframesWithDuration:duration delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.5 animations:^{
            intermediateView.frame = shrunkenFrame;
            toViewController.view.alpha = 0.5;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
            intermediateView.frame = fromFinalFrame;
            toViewController.view.alpha = 1.0;
        }];
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];
}

@end
