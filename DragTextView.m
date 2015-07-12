#import "DragTextView.h"

@implementation DragTextView

- (id) draggingDelegate
{
    return dragDelegate; 
}

- (void) setDraggingDelegate: (id) theDraggingDelegate
{
	dragDelegate = theDraggingDelegate;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if (dragDelegate && [dragDelegate respondsToSelector:@selector(draggingEntered:)])
	{
		return [dragDelegate draggingEntered:sender];
	}
	else
	{
		return [super draggingEntered:sender];
	}
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    if (dragDelegate && [dragDelegate respondsToSelector:@selector(draggingUpdated:)])
	{
		return [dragDelegate draggingUpdated:sender];
	}
	else
	{
		return [super draggingUpdated:sender];
	}
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    if (dragDelegate && [dragDelegate respondsToSelector:@selector(draggingExited:)])
	{
		[dragDelegate draggingExited:sender];
    }
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    if (dragDelegate && [dragDelegate respondsToSelector:@selector(prepareForDragOperation:)])
	{
		return [dragDelegate prepareForDragOperation:sender];
	}
	else
	{
		return [super prepareForDragOperation:sender];
	}
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    if (dragDelegate && [dragDelegate respondsToSelector:@selector(performDragOperation:)])
	{
		return [dragDelegate performDragOperation:sender];
	}
	else
	{
		return [super performDragOperation:sender];
	}
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    if (dragDelegate && [dragDelegate respondsToSelector:@selector(concludeDragOperation:)])
	{
		[dragDelegate concludeDragOperation:sender];
    }
}

@end
