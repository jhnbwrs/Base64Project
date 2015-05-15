//
//  ServiceProvider.m
//  Base64Anywhere
//

#import "ServiceProvider.h"
#import "AppDelegate.h"

@implementation ServiceProvider

@synthesize appController;

-(void)setLineBreakMode:(NSLineBreakMode)mode forView:(NSTextView*)view
{
    NSTextStorage *storage = [view textStorage];
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setLineBreakMode:mode];
    [storage addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, [storage length])];
    [style release];
}

-(void)setEncodedText:(NSString*)string
{
	[appController.encodedTextView setString:string];
	[self setLineBreakMode: NSLineBreakByCharWrapping forView:appController.encodedTextView];
	[appController.encodedTextView scrollToBeginningOfDocument:self];
	[appController.encodedTextView setEditable:NO];
}

//This is code that will be used when this thing actually supports base64 encoding files.
- (void) EncodeFile: (NSPasteboard*) pasteboard : (NSString*) error
{
    NSString* PBoardString = [[pasteboard stringForType: NSFilenamesPboardType] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if( !PBoardString )
	{
		return;
	}
	//This gives you a plist style string with your filename that looks like this:
	/* <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	 <plist version="1.0">
	 <array>
	 <string>/Users/homedirectory/Desktop/IMG_1783.jpg</string>
	 </array>
	 </plist>  */
	const char* pboardcstring = [PBoardString UTF8String];
	if( !pboardcstring )
	{
		return;
	}
	NSInteger   len = strlen(pboardcstring);
	NSData* plistData = [[NSData alloc] initWithBytes:pboardcstring length:len];
	NSPropertyListReadOptions read_options = 0;
	NSError* deserializationError = NULL;
	NSArray* fileArray = (NSArray*)[NSPropertyListSerialization propertyListWithData:plistData options:read_options format:nil error:&deserializationError];
	[plistData release];
	if( deserializationError )
	{
		return;
	}
	if( !fileArray )
	{
		return;
	}
	if( [fileArray count] <=0 )
	{
		return;
	}
	[appController startEncodeFileRequest];
	[appController taskStarted];
	NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(encodeFiles:) object:fileArray]autorelease];
    [thread start];
}

- (void) EncodeText: (NSPasteboard*) pasteboard : (NSString*) error
{
	if( !appController )
        return;
	NSString* toEncode = [pasteboard stringForType:NSPasteboardTypeString];
	[appController startEncodeRequest];
	[appController.plainTextView setString:toEncode];
	NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(encode:) object:pasteboard]autorelease];
    [thread start];
    return;
}

- (void) EncodeTextReturn: (NSPasteboard*) pasteboard : (NSString*) error
{
    if( !appController )
        return;
	NSString* toEncode = [pasteboard stringForType:NSPasteboardTypeString];
	[appController startEncodeRequest];
	[appController.plainTextView setString:toEncode];
	NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(encode:) object:pasteboard]autorelease];
    [thread start];
}

-(NSString*)removeAllWhiteSpace:(NSString*)original
{
    NSCharacterSet *whitespaces = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSArray *parts = [original componentsSeparatedByCharactersInSet:whitespaces];
    NSString* rval = [parts componentsJoinedByString:@""];
    return rval;
}

- (void) DecodeText: (NSPasteboard*) pasteboard : (NSString*) error
{
    if( !appController )
        return;
    
    NSString* pboardString = [pasteboard stringForType:NSPasteboardTypeString];
    NSString* noWhitespace = [self removeAllWhiteSpace:pboardString];
    NSString* rval = [self decode:noWhitespace];
    [appController.window makeKeyAndOrderFront:self];
    [appController.window orderFrontRegardless];
    
	[self setEncodedText:noWhitespace];

    [appController.plainTextView setString:rval];
    [appController.plainTextView scrollToBeginningOfDocument:self];
	[appController.plainTextView setEditable:NO];
    [self writeResultToClipBoard:pasteboard Result:rval];
    [rval release];
    return;
}

- (void) DecodeTextReturn: (NSPasteboard*) pasteboard : (NSString*) error
{
    NSString* pboardString = [pasteboard stringForType:NSPasteboardTypeString];
    NSString* noWhitespace = [self removeAllWhiteSpace:pboardString];
    NSString* rval = [self decode:noWhitespace];
    [self writeResultToClipBoard:pasteboard Result:rval];
    [rval release];
}

- (void) writeResultToClipBoard:(NSPasteboard *)pboard Result:(NSString*)result
{
    
    [pboard clearContents];
    [pboard writeObjects:[NSArray arrayWithObject:result]];
}

-(NSString*)decode:(NSString*)toDecode
{
    NSMutableString*  rval = nil;
    CFDataRef  dataToDecode = (CFDataRef)[toDecode dataUsingEncoding:NSUTF8StringEncoding];
    CFErrorRef error = NULL;
    
    appController.textToDecode = toDecode;
    
    SecTransformRef encodingRef = SecDecodeTransformCreate(kSecBase64Encoding, &error );
    SecTransformSetAttribute(encodingRef, kSecTransformInputAttributeName, dataToDecode, &error );
    CFDataRef resultData = SecTransformExecute(encodingRef,&error);
    rval = [[NSMutableString alloc] initWithBytes:CFDataGetBytePtr(resultData)
                                           length:CFDataGetLength(resultData)
                                         encoding:NSUTF8StringEncoding];
    if ( !rval )
    {
        appController.isDecodedHex = YES;
        rval = [[NSMutableString alloc] initWithCapacity:(CFDataGetLength(resultData) * 5)+1];
        /* It wasn't representable in UTF8 Encoding, probably contains at least some non printable data,
         * let's show a hex representation of the data..... */
        for( int i = 0; i < CFDataGetLength(resultData); i++)
        {
            int curr = CFDataGetBytePtr(resultData)[i];
            if( i == 0 )
                [rval appendFormat:@"0x%02x", curr];
            else
                [rval appendFormat:@" 0x%02x", curr];
        }
    }
    else
    {
        appController.isDecodedHex = NO;
    }
    NSData* decoded = [NSData dataWithData:(NSData*)resultData];
    [appController finishedDecodeRequest:decoded];
    return rval;
}

-(void)finishedEncodingText:(NSString*)text
{
	
    [appController.window makeKeyAndOrderFront:self];
    [appController.window orderFrontRegardless];
    [appController.plainTextView scrollToBeginningOfDocument:self];
	[appController.plainTextView setEditable:NO];
    [self setEncodedText:text];
	[appController finishedEncodeRequest];
    appController.isDecodedHex = NO;
    [text release];
}

-(void)encode:(NSPasteboard*)pasteboard
{
	NSString* toEncode = [pasteboard stringForType:NSPasteboardTypeString];
    NSString*  rval = nil;
    CFDataRef  dataToEncode = (CFDataRef)[toEncode dataUsingEncoding:NSUTF8StringEncoding];
    CFErrorRef error = NULL;
    SecTransformRef encodingRef = SecEncodeTransformCreate(kSecBase64Encoding, &error );
    SecTransformSetAttribute(encodingRef, kSecTransformInputAttributeName, dataToEncode, &error );
    CFDataRef resultData = SecTransformExecute(encodingRef,&error);
    
    rval = [[NSString alloc] initWithBytes:CFDataGetBytePtr(resultData)
                                    length:CFDataGetLength(resultData)
                                  encoding:NSUTF8StringEncoding];
	[self performSelectorOnMainThread:@selector(finishedEncodingText:) withObject:rval waitUntilDone:NO];
	[self writeResultToClipBoard:pasteboard Result:rval];
}

- (NSString*) encodeFile:(NSString*)filePath
{
	NSString*  rval = nil;
    CFDataRef  dataToEncode = (CFDataRef)[NSData dataWithContentsOfFile:filePath];
    CFErrorRef error = NULL;
    
    SecTransformRef encodingRef = SecEncodeTransformCreate(kSecBase64Encoding, &error );
    SecTransformSetAttribute(encodingRef, kSecTransformInputAttributeName, dataToEncode, &error );
    CFDataRef resultData = SecTransformExecute(encodingRef,&error);
    
    rval = [[NSString alloc] initWithBytes:CFDataGetBytePtr(resultData)
                                    length:CFDataGetLength(resultData)
                                  encoding:NSUTF8StringEncoding];
	return rval;
}

- (void)encodingFilesFinished:(NSString*)text
{
	appController.isDecodedHex = NO;
	[appController.window makeKeyAndOrderFront:self];
	[appController.window orderFrontRegardless];
	[self setEncodedText:text];
	[appController taskFinished];
	[text release];
}

- (void)sendFileFinishedNotification:(NSString*)file
{
	[appController finishedEncodeFileRequest:file];
}

- (void) encodeFiles:(NSArray*)fileArray
{
	NSString* rval = nil;
	NSString* file = [fileArray objectAtIndex:0];
	if( ![[NSFileManager defaultManager] fileExistsAtPath:file] )
	{
		rval = [[NSString alloc] initWithFormat:@"ERROR: File at path %@, doesn't exist",file];
		goto FINISHED;
	}
	NSDictionary* dict = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:nil];
	if( !dict )
	{
		rval = [[NSString alloc] initWithFormat:@"ERROR: Unable to get attributes for file: %@",file];
		goto FINISHED;
	}
	if( [dict fileSize] > 30000000 )
	{
		rval = [[NSString alloc] initWithFormat:@"ERROR: File is too large!"];
		goto FINISHED;
	}
FINISHED:
	rval = [self encodeFile:file];
	[self performSelectorOnMainThread:@selector(encodingFilesFinished:) withObject:rval waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(sendFileFinishedNotification:) withObject:file waitUntilDone:NO];
}

@end
