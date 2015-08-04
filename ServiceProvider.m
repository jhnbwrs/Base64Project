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
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        [self encodeFiles:fileArray];
    }];
    [[NSOperationQueue mainQueue] addOperation:operation];
}

- (void) EncodeText: (NSPasteboard*) pasteboard : (NSString*) error
{
	if( !appController )
        return;
	NSString* toEncode = [pasteboard stringForType:NSPasteboardTypeString];
	[appController startEncodeRequest];
	[appController.plainTextView setString:toEncode];
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(encode:) object:pasteboard];
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
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(encode:) object:pasteboard];
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
    
    [appController startDecodeRequest];
    NSString* pboardString = [pasteboard stringForType:NSPasteboardTypeString];
    NSString* noWhitespace = [self removeAllWhiteSpace:pboardString];
    [self setEncodedText:noWhitespace];
    NSString* rval = [self decode:noWhitespace];
    [appController.window makeKeyAndOrderFront:self];
    [appController.window orderFrontRegardless];
    [appController.plainTextView setString:rval];
    [appController.plainTextView scrollToBeginningOfDocument:self];
	[appController.plainTextView setEditable:NO];
    [self writeResultToClipBoard:pasteboard Result:rval];
    return;
}

- (void) DecodeTextReturn: (NSPasteboard*) pasteboard : (NSString*) error
{
    if( !appController )
        return;
    [appController startDecodeRequest];
    NSString* pboardString = [pasteboard stringForType:NSPasteboardTypeString];
    NSString* noWhitespace = [self removeAllWhiteSpace:pboardString];
    NSString* rval = [self decode:noWhitespace];
    [self writeResultToClipBoard:pasteboard Result:rval];
}

- (void) writeResultToClipBoard:(NSPasteboard *)pboard Result:(NSString*)result
{
    
    [pboard clearContents];
    [pboard writeObjects:[NSArray arrayWithObject:result]];
}

-(NSString*)decode:(NSString*)toDecode
{
    NSMutableString*  rval = nil;
    CFDataRef  dataToDecode = (__bridge CFDataRef)[toDecode dataUsingEncoding:NSUTF8StringEncoding];
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
    NSData* decoded = [NSData dataWithData:CFBridgingRelease(resultData)];
    [appController finishedDecodeRequest:decoded];
    CFRelease(encodingRef);
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
}

-(NSData*)convertHexStringToBytes:(NSString*)hexString
{
    hexString = [hexString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *rval = [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [hexString length]/2; i++)
    {
        byte_chars[0] = [hexString characterAtIndex:i*2];
        byte_chars[1] = [hexString characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [rval appendBytes:&whole_byte length:1];
    }
    return rval;
}

-(void)encode:(NSPasteboard*)pasteboard
{
	NSString*  toEncode = [pasteboard stringForType:NSPasteboardTypeString];
    NSString*  rval = nil;
    BOOL       treatAsHexString = NO;
    CFDataRef dataToEncode = nil;
    
    //TODO: add some UI and or smarts to switch this flag back and forth
    if( treatAsHexString )
        dataToEncode = (__bridge CFDataRef)[self convertHexStringToBytes:toEncode];
    else
        dataToEncode = (__bridge CFDataRef)[toEncode dataUsingEncoding:NSUTF8StringEncoding];
    
    CFErrorRef error = NULL;
    SecTransformRef encodingRef = SecEncodeTransformCreate(kSecBase64Encoding, &error );
    SecTransformSetAttribute(encodingRef, kSecTransformInputAttributeName, dataToEncode, &error );
    CFDataRef resultData = SecTransformExecute(encodingRef,&error);
    
    rval = [[NSString alloc] initWithBytes:CFDataGetBytePtr(resultData)
                                    length:CFDataGetLength(resultData)
                                  encoding:NSUTF8StringEncoding];
    CFRelease(resultData);
    CFRelease(encodingRef);
	[self performSelectorOnMainThread:@selector(finishedEncodingText:) withObject:rval waitUntilDone:NO];
	[self writeResultToClipBoard:pasteboard Result:rval];
}

- (NSString*) encodeFile:(NSString*)filePath
{
	NSString*  rval = nil;
    CFDataRef  dataToEncode = (__bridge CFDataRef)[NSData dataWithContentsOfFile:filePath];
    CFErrorRef error = NULL;
    
    SecTransformRef encodingRef = SecEncodeTransformCreate(kSecBase64Encoding, &error );
    SecTransformSetAttribute(encodingRef, kSecTransformInputAttributeName, dataToEncode, &error );
    CFDataRef resultData = SecTransformExecute(encodingRef,&error);
    rval = [[NSString alloc] initWithBytes:CFDataGetBytePtr(resultData)
                                    length:CFDataGetLength(resultData)
                                  encoding:NSUTF8StringEncoding];
    CFRelease(resultData);
    CFRelease(encodingRef);
	return rval;
}

- (void)encodingFilesFinished:(NSString*)text
{
	appController.isDecodedHex = NO;
	[appController.window makeKeyAndOrderFront:self];
	[appController.window orderFrontRegardless];
	[self setEncodedText:text];
	[appController taskFinished];
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
	}
    else
    {
        NSDictionary* dict = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:nil];
        if( !dict )
        {
            rval = [[NSString alloc] initWithFormat:@"ERROR: Unable to get attributes for file: %@",file];
        }
        if( [dict fileSize] > 30000000 )
        {
            rval = [[NSString alloc] initWithFormat:@"ERROR: File is too large!"];
        }
    }
    if( rval == nil )
    {
        rval = [self encodeFile:file];
    }
	[self performSelectorOnMainThread:@selector(encodingFilesFinished:) withObject:rval waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(sendFileFinishedNotification:) withObject:file waitUntilDone:NO];
}

@end
