//
//  ProjectPathHelper.m
//  BundleIDHelper
//
//  Created by MichaelMo on 9/27/16.
//  Copyright © 2016 MichaelMo. All rights reserved.
//

#import "ProjectPathHelper.h"
@import AppKit;

@implementation ProjectPathHelper

+ (NSString *)workspacePath{
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];
    
    id workSpace;
    
    for (id controller in workspaceWindowControllers) {
        if ([[controller valueForKey:@"window"] isEqual:[NSApp keyWindow]]) {
            workSpace = [controller valueForKey:@"_workspace"];
        }
    }
    
    NSString *workspacePath = [[workSpace valueForKey:@"representingFilePath"] valueForKey:@"_pathString"];
    return workspacePath;
}

@end
