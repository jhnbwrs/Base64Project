//
//  AppDelegate.m
//  Base64Anywhere
//

/* 
 
 Future:
 
 1 - Enable service for image files.
 2 - Add CSSify button
 3 - Add option to save binary data as a file.

 */

#import  "AppDelegate.h"
#include "ServiceProvider.h"

@implementation NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    NSRange range = NSMakeRange(0, [attrString length]);
    
    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
    
    // make the text appear in blue
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    
    // next make the text appear with an underline
    [attrString addAttribute:
     NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];
    
    [attrString endEditing];
    
    return [attrString autorelease];
}
@end

@implementation AppDelegate

@synthesize implbitsLink;
@synthesize plainTextView;
@synthesize encodedTextView;
@synthesize window;
@synthesize showPrintable;
@synthesize textToDecode;
@synthesize isDecodedHex;
@synthesize progressBar;

- (void)dealloc
{
    [plainTextView release];
    [encodedTextView release];
    [showPrintable release];
    [textToDecode release];
    [progressBar release];
    [super dealloc];
}

-(void)setHyperlinkWithTextField:(NSTextField*)inTextField
{
    // both are needed, otherwise hyperlink won't accept mousedown
    [inTextField setAllowsEditingTextAttributes: YES];
    [inTextField setSelectable: YES];
    
    NSURL* url = [NSURL URLWithString:@"http://www.implbits.com"];
    
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc] init];
    [string appendAttributedString: [NSAttributedString hyperlinkFromString:@"Implbits Software" withURL:url]];
    
    // set the attributed string to the NSTextField
    [inTextField setAttributedStringValue: string];
    [string release];
}

- (void) awakeFromNib
{
    [self setHyperlinkWithTextField:implbitsLink];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
    ServiceProvider* provider = [[ServiceProvider alloc] init];
    provider.appController = self;
	[NSApp setServicesProvider:provider];
    //use a fixed width font.
    NSFont* font = [NSFont fontWithName:@"Courier" size:12];
    [plainTextView setFont:font];
    [encodedTextView setFont:font];
    [showPrintable setHidden:YES];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	return NSTerminateNow;
}

- (void)taskStarted
{
    [progressBar setHidden:NO];
    [progressBar startAnimation:self];
}

- (void)taskFinished
{
    [progressBar setHidden:YES];
    [progressBar stopAnimation:self];
}

- (void)convertTaskEnded:(id)object
{
    if(showPrintableState)
    {
        NSString* title = @"Show Hex Only";
        [showPrintable setTitle:title];
    }
    else
    {
        NSString* title = @"Show Printable Chars";
        [showPrintable setTitle:title];
    }    
    [showPrintable setEnabled:YES];
    [self taskFinished];
}

- (void)changeText:(id)arg
{
    CFDataRef  dataToDecode = (CFDataRef)[textToDecode dataUsingEncoding:NSUTF8StringEncoding];
    CFErrorRef error = NULL;
    
    SecTransformRef encodingRef = SecDecodeTransformCreate(kSecBase64Encoding, &error );
    SecTransformSetAttribute(encodingRef, kSecTransformInputAttributeName, dataToDecode, &error );
    CFDataRef resultData = SecTransformExecute(encodingRef,&error);
    NSMutableString* output = [[NSMutableString alloc] initWithBytes:CFDataGetBytePtr(resultData)
                                                              length:CFDataGetLength(resultData)
                                                            encoding:NSUTF8StringEncoding];
    if ( !output )
    {
        BOOL printingHex = YES;
        BOOL switchedState = NO;
        output = [[NSMutableString alloc] initWithCapacity:(CFDataGetLength(resultData)*5)+1];
        for( int i = 0; i < CFDataGetLength(resultData); i++)
        {
            int curr = CFDataGetBytePtr(resultData)[i];
            if( isprint(curr) && showPrintableState == YES )
            {
                char cstr[2];
                cstr[0] = curr;
                cstr[1] = '\0';
                
                if( printingHex )
                    switchedState = YES;
                else
                    switchedState = NO;
                printingHex = NO;
                
                if( i == 0 )
                    [output appendFormat:@"%s",cstr];
                else
                    [output appendFormat:@"%s%s",(switchedState ? "\n" : ""),cstr];
            }
            else
            {
                if( !printingHex )
                    switchedState = YES;
                else
                    switchedState = NO;
                printingHex = YES;
                if( i == 0 )
                    [output appendFormat:@"0x%02x", curr];
                else
                    [output appendFormat:@" %s0x%02x", (switchedState ? "\n" : ""), curr];
            }
        }
    }
    [plainTextView performSelectorOnMainThread:@selector(setString:) withObject:output waitUntilDone:YES];
    [plainTextView performSelectorOnMainThread:@selector(scrollToBeginningOfDocument) withObject:self waitUntilDone:YES];
	[plainTextView performSelectorOnMainThread:@selector(setEditable) withObject:nil waitUntilDone:YES];
    [self performSelectorOnMainThread:@selector(convertTaskEnded:) withObject:(nil) waitUntilDone:YES];
    [output release];
}

- (IBAction)showPrintableClicked:(id)sender
{
    showPrintableState = !showPrintableState;
    NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(changeText:) object:nil];
    [thread start];
    [showPrintable setEnabled:NO];
    [self taskStarted];
}

- (void) startEncodeRequest
{
	self.encodedTextBox.title = @"Base64 Encoded Text";
	[self.plainTextView setString:@""];
}

- (void) startDecodeRequest
{
	self.encodedTextBox.title = @"Base64 Encoded Text";
	[self.plainTextView setString:@""];
}

- (void) startEncodeFileRequest
{
	self.encodedTextBox.title = @"Base64 Encoded File";
	[self.plainTextView setString:@""];
}

- (void) finishedEncodeFileRequest:(NSString*)filename
{
	[showPrintable setHidden:YES];
	[[[[NSApplication sharedApplication] windows]objectAtIndex:0] setTitle:[filename lastPathComponent]];
}

- (void) finishedEncodeRequest
{
    [showPrintable setHidden:YES];
}

- (void) finishedDecodeRequest
{
    if( isDecodedHex )
        [showPrintable setHidden:NO];
    else
        [showPrintable setHidden:YES];
}

- (void) copyStringToPasteBoard:(NSString*)value
{
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    if( pasteboard )
    {
        [pasteboard declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: NULL];
        [pasteboard setString: value forType: NSStringPboardType];
    }
}

- (IBAction)copyDecodedClicked:(id)sender
{
    [self copyStringToPasteBoard:[plainTextView string]];
}

- (IBAction)copyEncodedClicked:(id)sender
{
    [self copyStringToPasteBoard:[encodedTextView string]];
}

@end
