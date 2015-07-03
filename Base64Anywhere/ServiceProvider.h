//
//  ServiceProvider.h
//  Base64Anywhere
//

#import <Foundation/Foundation.h>

@class AppDelegate;

@interface ServiceProvider : NSObject
{
    AppDelegate* appController;
}

- (void) EncodeFile: (NSPasteboard*) pasteboard : (NSString*) error;
- (void)EncodeText: (NSPasteboard*) pasteboard : (NSString*) error;
- (void)DecodeText: (NSPasteboard*) pasteboard : (NSString*) error;
- (void)EncodeTextReturn: (NSPasteboard*) pasteboard : (NSString*) error;
- (void)DecodeTextReturn: (NSPasteboard*) pasteboard : (NSString*) error;

@property (strong) AppDelegate* appController;

@end
