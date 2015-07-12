#import <Cocoa/Cocoa.h>

@interface DragTextView : NSTextView
{
	id	dragDelegate;
}
- (id) draggingDelegate;
- (void) setDraggingDelegate: (id) theDraggingDelegate;
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender;
- (void)draggingExited:(id <NSDraggingInfo>)sender;
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender;

@end
