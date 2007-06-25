/*=========================================================================
Program:   OsiriX

Copyright (c) OsiriX Team
All rights reserved.
Distributed under GNU - GPL

See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

This software is distributed WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.
=========================================================================*/

#import "BrowserMatrix.h"
#import "BrowserController.h"

static NSString *albumDragType = @"Osirix Album drag";

@implementation BrowserMatrix

- (void) selectCell:(NSEvent*) theEvent
{
	#if !__LP64__
	int row, column;
	#else
	long row, column;
	#endif
 
	if( [self getRow: &row column: &column forPoint: [self convertPoint:[theEvent locationInWindow] fromView:nil]])
	{
		if( [theEvent modifierFlags] & NSShiftKeyMask )
		{
			int start = [[self cells] indexOfObject: [[self selectedCells] objectAtIndex: 0]];
			int end = [[self cells] indexOfObject: [self cellAtRow:row column:column]];
			
			[self setSelectionFrom:start to:end anchor:start highlight: YES];
			
		}
		else if( [theEvent modifierFlags] & NSCommandKeyMask )
		{
			int start = [[self cells] indexOfObject: [[self selectedCells] objectAtIndex: 0]];
			int end = [[self cells] indexOfObject: [self cellAtRow:row column:column]];
			
			if( [[self selectedCells] containsObject:[self cellAtRow:row column:column]])
				[self setSelectionFrom:end to:end anchor:end highlight: NO];
			else
				[self setSelectionFrom:end to:end anchor:end highlight: YES];

		}
		else
		{
			if( [[self cellAtRow:row column:column] isHighlighted] == NO) [self selectCellAtRow: row column:column];
		}
	}
}

- (void) startDrag:(NSEvent *) event
{
	NSLog( @"startDrag");
	
	NS_DURING
	
	NSSize dragOffset = NSMakeSize(0.0, 0.0);
    
	NSPoint event_location = [event locationInWindow];
	NSPoint local_point = [self convertPoint:event_location fromView:nil];
	
	local_point.x -= 35;
	local_point.y += 35;
	
	NSArray				*cells = [self selectedCells];
	
	if( [cells count])
	{
		int		i, width = 0;
		NSImage	*firstCell = [[cells objectAtIndex: 0] image];
		
		#define MARGIN 3
		
		width += MARGIN;
		for( i = 0; i < [cells count]; i++)
		{
			width += [[[cells objectAtIndex: i] image] size].width;
			width += MARGIN;
		}
		
		NSImage *thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize( width, 70+6)] autorelease];
		
		[thumbnail lockFocus];
		
		[[NSColor grayColor] set];
		NSRectFill(NSMakeRect(0,0,width, 70+6));
		
		width = 0;
		width += MARGIN;
		for( i = 0; i < [cells count]; i++)
		{
			NSRectFill( NSMakeRect( width, 0, [firstCell size].width, [firstCell size].height));
			
			NSImage	*im = [[cells objectAtIndex: i] image];
			[im drawAtPoint: NSMakePoint(width, 3) fromRect:NSMakeRect(0,0,[im size].width, [im size].height) operation: NSCompositeCopy fraction: 0.8];
		
			width += [im size].width;
		    width += MARGIN;
		}
		[thumbnail unlockFocus];
		
		NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSDragPboard]; 
		
		[pboard declareTypes:[NSArray arrayWithObjects:  albumDragType, NSFilesPromisePboardType, NSFilenamesPboardType, NSStringPboardType, nil]  owner:self];
		[pboard setPropertyList:0L forType:albumDragType];
		[pboard setPropertyList:[NSArray arrayWithObject:@"dcm"] forType:NSFilesPromisePboardType];
		
		NSMutableArray	*objects = [NSMutableArray array];
		for( i = 0; i < [cells count]; i++)
		{
			[objects addObject: [[[BrowserController currentBrowser] matrixViewArray] objectAtIndex: [[cells objectAtIndex: i] tag]]];
		}
		[[BrowserController currentBrowser] setDraggedItems: objects];
		
		[self dragImage:thumbnail
				at:local_point
				offset:dragOffset
				event:event 
				pasteboard:pboard 
				source:self 
				slideBack:YES];
	}
	
	NS_HANDLER
		NSLog(@"Exception while dragging: %@", [localException description]);
	NS_ENDHANDLER
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
	if( [[[dropDestination path] lastPathComponent] isEqualToString:@".Trash"])
	{
		[[BrowserController currentBrowser] delItem: [[[[BrowserController currentBrowser] oMatrix] menu] itemAtIndex: 0]];
		return 0L;
	}
	else
	{
		NSMutableArray	*dicomFiles2Export = [NSMutableArray array];
		NSArray			*filesToExport = [[BrowserController currentBrowser] filesForDatabaseMatrixSelection: dicomFiles2Export];
		
		return [[BrowserController currentBrowser] exportDICOMFileInt: [dropDestination path] files: filesToExport objects: dicomFiles2Export];
	}
}

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationEvery;
}

- (void) mouseDown:(NSEvent *)event
{
	if ([event modifierFlags]  & NSAlternateKeyMask)
	{
		[self startDrag: event];
	}
	else
	{		
		BOOL keepOn = YES;
		NSPoint mouseLoc = [self convertPoint:[event locationInWindow] fromView:nil];
		
		[NSEvent stopPeriodicEvents];
		[NSEvent startPeriodicEventsAfterDelay: 0 withPeriod:0.001];
		
		NSDate	*start = [NSDate date];
		NSEvent *ev = 0L;
		
		do
		{
			ev = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			
			switch ([ev type])
			{
			case NSLeftMouseDragged:
				keepOn = NO;
				break;
			case NSLeftMouseUp:
				keepOn = NO;
				break;
			}
		}while (keepOn && [start timeIntervalSinceNow] >= -1);
		
		if( keepOn)
		{
			[self selectCell: event];
			[self startDrag: event];
		}
		else
		{
			[super mouseDown: ev];
		}
		
		[NSEvent stopPeriodicEvents];
	}
}

- (void) rightMouseDown:(NSEvent *)theEvent
{
	[self selectCell: theEvent];
	
	[[BrowserController currentBrowser] matrixPressed: self];
	
	[super rightMouseDown: theEvent];
 }

@end
