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
    
    return attrString;
}
@end

@implementation AppDelegate

@synthesize implbitsLink;
@synthesize plainTextView;
@synthesize plainTextBox;
@synthesize encodedTextView;
@synthesize encodedTextBox;
@synthesize window;
@synthesize showPrintable;
@synthesize textToDecode;
@synthesize isDecodedHex;
@synthesize progressBar;
@synthesize imageView;


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
    CFDataRef  dataToDecode = (__bridge CFDataRef)[textToDecode dataUsingEncoding:NSUTF8StringEncoding];
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
	[imageView setHidden:YES];
	[plainTextView setHidden:YES];
	[encodedTextView setHidden:YES];
}

- (void) startDecodeRequest
{
	self.encodedTextBox.title = @"Base64 Encoded Text";
	[self.plainTextView setString:@""];
	[imageView setHidden:YES];
	[plainTextView setHidden:YES];
	[encodedTextView setHidden:YES];
}

- (void) startEncodeFileRequest
{
	self.encodedTextBox.title = @"Base64 Encoded File";
	[self.plainTextView setString:@""];
	[self.encodedTextView setString:@""];
	[imageView setHidden:YES];
	[plainTextView setHidden:YES];
	[encodedTextView setHidden:YES];
}

- (BOOL)isFileImage:(NSString*)path
{
	NSString* ext = [path pathExtension];
	if( [ext caseInsensitiveCompare:@"tiff"] == NSOrderedSame ||
	    [ext caseInsensitiveCompare:@"jpg"] == NSOrderedSame ||
	    [ext caseInsensitiveCompare:@"jpeg"] == NSOrderedSame ||
	    [ext caseInsensitiveCompare:@"png"] == NSOrderedSame ||
	    [ext caseInsensitiveCompare:@"gif"] == NSOrderedSame)
	{
		return YES;
	}
	return NO;
}

- (void) finishedEncodeFileRequest:(NSString*)filename
{
    decodedData = nil;
	[showPrintable setHidden:YES];
	[[[[NSApplication sharedApplication] windows]objectAtIndex:0] setTitle:[filename lastPathComponent]];
	if( [self isFileImage:filename] )
	{
		NSImage* encodedImage = [[NSImage alloc] initWithContentsOfFile:filename];
		[imageView setImage:encodedImage];
		[imageView setHidden:NO];
		[plainTextView setHidden:YES];
		[plainTextBox setHidden:YES];
	}
	else
	{
		[plainTextView setHidden:NO];
		[plainTextBox setHidden:NO];
		[imageView setHidden:YES];
	}
	[encodedTextView setHidden:NO];
	[encodedTextBox setHidden:NO];
}

- (void) finishedEncodeRequest
{
    decodedData = nil;
    [showPrintable setHidden:YES];
	[plainTextView setHidden:NO];
	[plainTextBox setHidden:NO];
	[encodedTextView setHidden:NO];
	[encodedTextBox setHidden:NO];
}

- (BOOL) isEncodedImage:(NSData*)decoded
{
    NSImage* image = [[NSImage alloc] initWithData:decoded];
    if( image )
    {
        [imageView setImage:image];
        [imageView setHidden:NO];
        [plainTextView setHidden:YES];
        [plainTextBox setHidden:YES];
        [encodedTextView setHidden:NO];
        [encodedTextBox setHidden:NO];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void) finishedDecodeRequest:(NSData*)decoded
{
    decodedData = decoded;
    if( ![self isEncodedImage:decoded] )
    {
        if( isDecodedHex )
            [showPrintable setHidden:NO];
        else
            [showPrintable setHidden:YES];
        [plainTextView setHidden:NO];
        [plainTextBox setHidden:NO];
        [encodedTextView setHidden:NO];
        [encodedTextBox setHidden:NO];
        [imageView setHidden:YES];
    }
}

- (NSString*)userSelectFile
{
    NSSavePanel* saveDlg = [NSSavePanel savePanel];
    if ( [saveDlg runModal] == NSOKButton )
    {
        NSURL* file = [saveDlg URL];
        return [file path];
    }
    return nil;
}

- (IBAction)saveDecodedClicked:(id)sender
{
    if( !decodedData )
        return;
    NSString* filename = [self userSelectFile];
    if( !filename )
        return;
    [decodedData writeToFile:filename atomically:YES];
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
