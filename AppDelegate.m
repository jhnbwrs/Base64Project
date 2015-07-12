//
//  AppDelegate.m
//  Base64Anywhere
//

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

typedef enum
{
    HTML,
    CSS,
    XML,
    B64,
    URL
} ConversionType;

ConversionType currentState = B64;

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
@synthesize HTMLButton;
@synthesize CSSButton;
@synthesize URLButton;
@synthesize XMLButton;
@synthesize plainB64Button;


-(ServiceProvider*)getSP
{
    if( sp == nil)
    {
        sp = [[ServiceProvider alloc] init];
    }
    return sp;
}

-(void)setHyperlinkWithTextField:(NSTextField*)inTextField
{
    // both are needed, otherwise hyperlink won't accept mousedown
    [inTextField setAllowsEditingTextAttributes: YES];
    [inTextField setSelectable: YES];
    
    NSURL* url = [NSURL URLWithString:@"http://thecoderslife.blogspot.com/2015/06/adding-right-click-context-menu-to.html"];
    
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc] init];
    [string appendAttributedString: [NSAttributedString hyperlinkFromString:@"Get the code!" withURL:url]];
    
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
    [plainB64Button setState:NSOnState];
    [self.encodedTextView setDraggingDelegate:self];
    NSArray* types = [NSArray arrayWithObject: (NSString*)kUTTypeFileURL];
    [self.encodedTextView registerForDraggedTypes: (NSArray*)types ];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	return NSTerminateNow;
}

- (void) setButtonStates:(ConversionType)type
{
    if(type != HTML)
        [HTMLButton setState:NSOffState];
    if(type != XML)
        [XMLButton setState:NSOffState];
    if(type != CSS)
        [CSSButton setState:NSOffState];
    if(type != B64)
        [plainB64Button setState:NSOffState];
    if(type != URL)
        [URLButton setState:NSOffState];
}

- (IBAction) plainB64Clicked:(id)sender
{
    currentState = B64;
    [encodedTextView setString:encodedText];
    [self setButtonStates:B64];
}

- (IBAction) HTMLClicked:(id)sender
{
    currentState = HTML;
    NSString* newText = [[NSString alloc] initWithFormat:@"<img alt=\"\" src=\"data:image/%@;base64,%@\">",imageType,encodedText];
    [encodedTextView setString:newText];
    [self setButtonStates:HTML];
}

- (IBAction) CSSClicked:(id)sender
{
    currentState = CSS;
    NSString* newText = [[NSString alloc] initWithFormat:@"background-image:url(data:image/%@;base64,%@);",imageType,encodedText];
    [encodedTextView setString:newText];
    [self setButtonStates:CSS];
}

- (IBAction) XMLClicked:(id)sender
{
    currentState = XML;
    NSString* newText = [[NSString alloc] initWithFormat:@"<data encoding=\"base64\" mime-type=\"image/%@\">%@</data>",imageType, encodedText];
    [encodedTextView setString:newText];
    [self setButtonStates:XML];
}

- (IBAction) URLClicked:(id)sender
{
    currentState = URL;
    NSString* newText = [[NSString alloc] initWithFormat:@"data:image/%@;base64,%@",imageType,encodedText];
    [encodedTextView setString:newText];
    [self setButtonStates:URL];
}

- (void)taskStarted
{
    [implbitsLink setHidden:YES];
    [progressBar setHidden:NO];
    [progressBar setIndeterminate:YES];
    [progressBar setUsesThreadedAnimation:YES];
    [progressBar startAnimation:nil];
}

- (void)taskFinished
{
    [implbitsLink setHidden:NO];
    [progressBar setHidden:YES];
    [progressBar stopAnimation:nil];
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
    CFRelease(resultData);
    CFRelease(encodingRef);
    [plainTextView performSelectorOnMainThread:@selector(setString:) withObject:output waitUntilDone:YES];
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
    [self.encodedTextView setString:@""];
	[imageView setHidden:YES];
	[plainTextView setHidden:YES];
	[encodedTextView setHidden:YES];
}

- (void) startDecodeRequest
{
	self.encodedTextBox.title = @"Base64 Encoded Text";
	[self.plainTextView setString:@""];
    [self.encodedTextView setString:@""];
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
        if( [ext caseInsensitiveCompare:@"jpg"] == NSOrderedSame )
            imageType = @"jpeg";
        else
            imageType = [ext copy];
		return YES;
	}
	return NO;
}

- (void) showHideForImageEncode:(BOOL)isImage
{
    [plainTextView setHidden:isImage];
    [plainTextBox setHidden:isImage];
    [imageView setHidden:!isImage];
    [HTMLButton setHidden:!isImage];
    [CSSButton setHidden:!isImage];
    [URLButton setHidden:!isImage];
    [plainB64Button setHidden:!isImage];
    [XMLButton setHidden:!isImage];
    if( isImage )
    {
        encodedText = [[encodedTextView string] copy];
        if( currentState == XML)
        {
            [self XMLClicked:self];
        }
        else
        if (currentState == B64)
        {
            [self plainB64Clicked:self];
        }
        else
        if (currentState == CSS)
        {
            [self CSSClicked:self];
        }
        else
        if (currentState == HTML)
        {
            [self HTMLClicked:self];
        }
        else
        if (currentState == URL)
        {
            [self URLClicked:self];
        }
    }
}

- (void) finishedEncodeFileRequest:(NSString*)filename
{
    self.decodedData = nil;
    [encodedTextView setTextColor:[NSColor blackColor]];
	[showPrintable setHidden:YES];
	[[[[NSApplication sharedApplication] windows]objectAtIndex:0] setTitle:[filename lastPathComponent]];
	if( [self isFileImage:filename] )
	{
		NSImage* encodedImage = [[NSImage alloc] initWithContentsOfFile:filename];
		[imageView setImage:encodedImage];
        [self showHideForImageEncode:YES];
	}
	else
	{
        encodedText = [[encodedTextView string] copy];
        [self showHideForImageEncode:NO];
	}
	[encodedTextView setHidden:NO];
	[encodedTextBox setHidden:NO];
}

- (void) finishedEncodeRequest
{
    self.decodedData = nil;
    [encodedTextView setTextColor:[NSColor blackColor]];
    [showPrintable setHidden:YES];
    [self showHideForImageEncode:NO];
	[encodedTextView setHidden:NO];
	[encodedTextBox setHidden:NO];
    encodedText = [[encodedTextView string] copy];
}

- (BOOL) isEncodedImage:(NSData*)decoded
{
    NSImage* image = [[NSImage alloc] initWithData:decoded];
    if( image )
    {
        [imageView setImage:image];
        [imageView setHidden:NO];
        [self showHideForImageEncode:YES];
        [plainTextView setHidden:YES];
        [plainTextBox setHidden:YES];
        [encodedTextView setHidden:NO];
        [encodedTextBox setHidden:NO];
        return YES;
    }
    return NO;
}

- (void) finishedDecodeRequest:(NSData*)decoded
{
    self.decodedData = decoded;
    if( ![self isEncodedImage:decoded] )
    {
        [encodedTextView setTextColor:[NSColor blackColor]];
        if( isDecodedHex )
        {
            [showPrintable setHidden:NO];
        }
        else
        {
            [showPrintable setHidden:YES];
        }
        [plainTextView setHidden:NO];
        [plainTextBox setHidden:NO];
        [encodedTextView setHidden:NO];
        [encodedTextBox setHidden:NO];
        [imageView setHidden:YES];
    }
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

- (NSWindow *)draggingDestinationWindow
{
    return self.window;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return NSDragOperationLink;
}
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    return NSDragOperationLink;
}
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSURLPboardType] )
    {
        NSURL *fileURL = [NSURL URLFromPasteboard:pboard];
        NSString* filePath = [NSString stringWithUTF8String:[fileURL fileSystemRepresentation]];
        NSArray* files = [[NSArray alloc] initWithObjects:filePath, nil];
        [self startEncodeFileRequest];
        [self taskStarted];
        [self getSP].appController = self;
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [[self getSP] encodeFiles:files];
        }];
        [[NSOperationQueue mainQueue] addOperation:operation];
    }
    return YES;
}

-(BOOL)isBase64Data:(NSString *)input
{
    if ([input length] % 4 == 0) {
        static NSCharacterSet *invertedBase64CharacterSet = nil;
        if (invertedBase64CharacterSet == nil) {
            invertedBase64CharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="]invertedSet];
        }
        return [input rangeOfCharacterFromSet:invertedBase64CharacterSet options:NSLiteralSearch].location == NSNotFound;
    }
    return NO;
}

- (IBAction)saveDecodedClicked:(id)sender
{
    if( !self.decodedData )
        return;
    NSString* filename = [self userSelectFile];
    if( !filename )
        return;
    [self.decodedData writeToFile:filename atomically:YES];
}

- (IBAction) pasteAction:(id)sender
{
    NSFont* font = [NSFont fontWithName:@"Courier" size:12];
    [encodedTextView setFont:font];
    [encodedTextView setTextColor:[NSColor blackColor]];
    [encodedTextView setString: @""];
    NSString* pasteValue = [[NSPasteboard generalPasteboard] stringForType: NSStringPboardType];
    [self getSP].appController = self;
    if( [self isBase64Data:pasteValue] )
    {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [[self getSP] DecodeText:[NSPasteboard generalPasteboard] :nil];
        }];
        [[NSOperationQueue mainQueue] addOperation:operation];
    }
    else
    {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [[self getSP] EncodeText:[NSPasteboard generalPasteboard] :nil];
        }];
        [[NSOperationQueue mainQueue] addOperation:operation];
    }
}

- (IBAction) copyAction:(id)sender
{
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    if( pasteboard )
    {
        [pasteboard declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: NULL];
        [pasteboard setString: self.encodedTextView.string forType: NSStringPboardType];
    }
}

- (IBAction) copyDecodedAction:(id)sender
{
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    if( pasteboard )
    {
        [pasteboard declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: NULL];
        [pasteboard setString: self.plainTextView.string forType: NSStringPboardType];
    }
}




@end
