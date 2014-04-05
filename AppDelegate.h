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
    NSWindow*    window;
    NSButton*    showPrintable;
    NSTextField* implbitsLink;
    NSString*    textToDecode;
    NSProgressIndicator* progressBar;
    BOOL         isDecodedHex;
    BOOL         showPrintableState;
}

@property (assign) IBOutlet NSWindow* window;
@property (retain) IBOutlet NSTextView* plainTextView;
@property (retain) IBOutlet NSTextView* encodedTextView;
@property (retain) IBOutlet NSButton* showPrintable;
@property (retain) IBOutlet NSProgressIndicator* progressBar;
@property (retain) IBOutlet NSBox* encodedTextBox;
@property (copy)   NSString* textToDecode;
@property (assign) BOOL isDecodedHex;
@property (retain) IBOutlet NSTextField* implbitsLink;

- (IBAction)showPrintableClicked:(id)sender;
- (IBAction)copyDecodedClicked:(id)sender;
- (IBAction)copyEncodedClicked:(id)sender;
- (void) finishedEncodeRequest;
- (void) finishedDecodeRequest;
- (void) finishedEncodeFileRequest;
- (void) startEncodeRequest;
- (void) startDecodeRequest;
- (void) startEncodeFileRequest;

@end
