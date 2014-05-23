//
//  DynamicSandwichViewController.m
//  SandwichFlow
//
//  Created by Khanh Pham on 5/24/14.
//  Copyright (c) 2014 Colin Eberhardt. All rights reserved.
//

#import "DynamicSandwichViewController.h"
#import "SandwichViewController.h"
#import "AppDelegate.h"

@interface DynamicSandwichViewController (){
    UIGravityBehavior *_gravity;
    UIDynamicAnimator *_animator;
    CGPoint _previousTouchPoint;
    BOOL _draggingView;
    UISnapBehavior *_snap;
    BOOL _viewDocked;
}

@property (nonatomic, strong) NSMutableArray *views;

@end

@implementation DynamicSandwichViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Background image
    UIImageView *bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background-LowerLayer.png"]];
    [self.view addSubview:bgView];
    
    // Header logo
    UIImageView *headerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Sarnie.png"]];
    headerView.center = CGPointMake(220, 190);
    [self.view addSubview:headerView];
    
    // Behavior
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    _gravity = [[UIGravityBehavior alloc] init];
    [_animator addBehavior:_gravity];
    _gravity.magnitude = 4.0f;
    
    // Add recipe views
    self.views = [NSMutableArray array];
    CGFloat offset = 250.0f;
    for (NSDictionary *sandwich in [self sandwiches]) {
        [self.views addObject:[self addRecipeAtOffset:offset forSandwich:sandwich]];
        offset -= 50.0f;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray*)sandwiches
{
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    return [appDelegate sandwiches];
}

- (UIView*)addRecipeAtOffset:(CGFloat)offset forSandwich:(NSDictionary*)sandwich
{
    CGRect frameForView = CGRectOffset(self.view.bounds, 0, self.view.bounds.size.height - offset);
    
    // Create view controller
    UIStoryboard *mainSB = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SandwichViewController *viewController = (SandwichViewController*)[mainSB instantiateViewControllerWithIdentifier:@"SandwichVC"];
    
    // Set the frame and provide data
    UIView *view = viewController.view;
    view.frame = frameForView;
    viewController.sandwich = sandwich;
    
    // Add as a child
    [self addChildViewController:viewController];
    [self.view addSubview:view];
    
    [viewController didMoveToParentViewController:self];
    
    // Gesture recognizer
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [view addGestureRecognizer:recognizer];
    
    // Create collision
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[view]];
    [_animator addBehavior:collision];
    
    // Lower boundary, where the tab rests
    CGFloat boundary = view.frame.origin.y + view.frame.size.height + 1;
    CGPoint boundaryStart = CGPointMake(0, boundary);
    CGPoint boundaryEnd = CGPointMake(self.view.bounds.size.width, boundary);
    
    [collision addBoundaryWithIdentifier:@1 fromPoint:boundaryStart toPoint:boundaryEnd];
    
    // Dock boundary
    CGPoint dockBoundaryStart = CGPointMake(0, 0);
    CGPoint dockBoundaryEnd = CGPointMake(self.view.bounds.size.width, 0);
    
    [collision addBoundaryWithIdentifier:@2 fromPoint:dockBoundaryStart toPoint:dockBoundaryEnd];
    collision.collisionDelegate = self;
    
    [_gravity addItem:view];
    
    UIDynamicItemBehavior *itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[view]];
    [_animator addBehavior:itemBehavior];
    
    return view;
}

- (void)handlePan:(UIPanGestureRecognizer*)gesture
{
    CGPoint touchPoint = [gesture locationInView:self.view];
    
    UIView *draggedView = gesture.view;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        // Was the pan initiated from the top of the recipe
        CGPoint dragStartLocation = [gesture locationInView:draggedView];
        
        if (dragStartLocation.y < 200.0f) {
            _draggingView = YES;
            _previousTouchPoint = touchPoint;
        }
    } else if (gesture.state == UIGestureRecognizerStateChanged && _draggingView) {
        // Handle dragging
        CGFloat offset = _previousTouchPoint.y - touchPoint.y;
        draggedView.center = CGPointMake(draggedView.center.x, draggedView.center.y - offset);
        _previousTouchPoint = touchPoint;
    } else if (gesture.state == UIGestureRecognizerStateEnded && _draggingView) {
        // The gesture has ended
        [self tryDockView:draggedView];
        [self addVelocityToView:draggedView fromGesture:gesture];
        [_animator updateItemUsingCurrentState:draggedView];
        _draggingView = NO;
    }
}

- (void)tryDockView:(UIView*)view
{
    BOOL viewHasReachedDockLocation = view.frame.origin.y < 100.0f;
    if (viewHasReachedDockLocation) {
        _snap = [[UISnapBehavior alloc] initWithItem:view snapToPoint:self.view.center];
        [_animator addBehavior:_snap];
        [self setAlphaWhenViewDocked:view alpha:0.0];
        _viewDocked = YES;
    } else {
        if (_viewDocked) {
            [_animator removeBehavior:_snap];
            [self setAlphaWhenViewDocked:view alpha:1.0];
            _viewDocked = NO;
        }
    }
}

- (void)setAlphaWhenViewDocked:(UIView*)view alpha:(CGFloat)alpha
{
    for (UIView *aView in self.views) {
        if (aView != view) {
            aView.alpha = alpha;
        }
    }
}

- (void)addVelocityToView:(UIView*)view fromGesture:(UIPanGestureRecognizer*)gesture
{
    CGPoint vel = [gesture velocityInView:self.view];
    vel.x = 0;
    UIDynamicItemBehavior *behavior = [self behaviorForView:view];
    [behavior addLinearVelocity:vel forItem:view];
}

- (UIDynamicItemBehavior*)behaviorForView:(UIView*)view
{
    for (UIDynamicItemBehavior *behavior in [_animator behaviors]) {
        if ([behavior class] == [UIDynamicItemBehavior class] && [behavior.items firstObject] == view) {
            return behavior;
        }
    }
    return nil;
}

- (void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier atPoint:(CGPoint)p
{
    if ([@2 isEqual:identifier]) {
        UIView *view = (UIView*)item;
        [self tryDockView:view];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
