//
//  AppDelegate.h
//  Base64Anywhere
//

#import <Cocoa/Cocoa.h>

@interface NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    NSTextView*  painTextView;
    NSTextView*  encodedTextView;
    NSWindow*    __unsafe_unretained window;
    NSButton*    showPrintable;
    NSTextField* implbitsLink;
    NSString*    textToDecode;
    NSProgressIndicator* progressBar;
    BOOL         isDecodedHex;
    BOOL         showPrintableState;
    NSData*      decodedData;
}

@property (unsafe_unretained) IBOutlet NSWindow* window;
@property (strong) IBOutlet NSTextView* plainTextView;
@property (strong) IBOutlet NSTextView* encodedTextView;
@property (strong) IBOutlet NSButton* showPrintable;
@property (strong) IBOutlet NSProgressIndicator* progressBar;
@property (strong) IBOutlet NSBox* encodedTextBox;
@property (strong) IBOutlet NSImageView* imageView;
@property (strong) IBOutlet NSBox* plainTextBox;
@property (copy)   NSString* textToDecode;
@property (assign) BOOL isDecodedHex;
@property (strong) IBOutlet NSTextField* implbitsLink;

- (IBAction)saveDecodedClicked:(id)sender;
- (IBAction)showPrintableClicked:(id)sender;
- (IBAction)copyDecodedClicked:(id)sender;
- (IBAction)copyEncodedClicked:(id)sender;
- (void) finishedEncodeRequest;
- (void) finishedDecodeRequest:(NSData*)decoded;
- (void) finishedEncodeFileRequest:(NSString*)filename;
- (void) startEncodeRequest;
- (void) startDecodeRequest;
- (void) startEncodeFileRequest;
- (void) taskStarted;
- (void) taskFinished;

@end
