//
//  AppDelegate.h
//  Base64Anywhere
//

#import <Cocoa/Cocoa.h>
#import "DragTextView.h"
#import "ServiceProvider.h"

@interface NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    NSWindow*        __unsafe_unretained window;
    NSString*        imageType;
    BOOL             showPrintableState;
    NSString*        encodedText;
    //Will only be used when we open a file directly in the app
    ServiceProvider* sp;
}

@property (unsafe_unretained) IBOutlet NSWindow* window;
@property (strong) IBOutlet NSTextView* plainTextView;
@property (strong) IBOutlet DragTextView* encodedTextView;
@property (strong) IBOutlet NSButton* showPrintable;

@property (strong) IBOutlet NSButton* plainB64Button;
@property (strong) IBOutlet NSButton* CSSButton;
@property (strong) IBOutlet NSButton* HTMLButton;
@property (strong) IBOutlet NSButton* XMLButton;
@property (strong) IBOutlet NSButton* URLButton;

@property (strong) IBOutlet NSProgressIndicator* progressBar;
@property (strong) IBOutlet NSBox* encodedTextBox;
@property (strong) IBOutlet NSImageView* imageView;
@property (strong) IBOutlet NSBox* plainTextBox;
@property (strong) IBOutlet NSTextField* implbitsLink;
@property (strong) NSData* decodedData;
@property (assign) BOOL isDecodedHex;
@property (copy)   NSString* textToDecode;
@property (assign) BOOL CopyEncodedText;

- (IBAction)showPrintableClicked:(id)sender;
- (IBAction)copyDecodedClicked:(id)sender;
- (IBAction)copyEncodedClicked:(id)sender;


- (IBAction) plainB64Clicked:(id)sender;
- (IBAction) HTMLClicked:(id)sender;
- (IBAction) CSSClicked:(id)sender;
- (IBAction) XMLClicked:(id)sender;
- (IBAction) URLClicked:(id)sender;

- (IBAction) pasteAction:(id)sender;
- (IBAction) copyAction:(id)sender;
- (IBAction) selectAllAction:(id)sender;

- (void) finishedEncodeRequest;
- (void) finishedDecodeRequest:(NSData*)decodeds;
- (void) finishedEncodeFileRequest:(NSString*)filename;
- (void) startEncodeRequest;
- (void) startDecodeRequest;
- (void) startEncodeFileRequest;
- (void) taskStarted;
- (void) taskFinished;
- (IBAction)saveDecodedClicked:(id)sender;

@end
