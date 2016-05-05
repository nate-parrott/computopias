//
//  Pushy.h
//  Phony Example
//
//  Created by Justin Brower on 3/28/16.
//  Copyright © 2016 Pushy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

// maximum number of polling attempts
#define MAX_POLL 10

// amount of time to wait before polling
#define MIN_DELAY .5

// enable debug statements
#define PUSHY_DEBUG

@interface Phony : NSObject <MFMessageComposeViewControllerDelegate> {
    NSString *applicationKey;
    NSString *applicationSecret;
    
    int pollCount;
    NSTimer *pollTimer;
    
    NSString *current_token_secret;
    NSString *current_token;
    NSString *current_phone_number;
    BOOL polling;
    
    NSString *_replyToPhone;
    NSString *_replyWithToken;
}

@property (nonatomic, copy, nullable) void (^handler)(BOOL, NSString* _Nullable, NSString* _Nullable);

/* Initializes pushy for a specific application */
+ (void)initWithAppKey:(NSString * _Nonnull)appKey secret:( NSString * _Nonnull )secret;

/* Returns the shared pushy instance. Don't lose this! :) */
+ (_Nonnull instancetype)sharedPhony;

/*   Contacts the pushy servers to obtain an authentication code.
 *
 *   Arguments:
 *      @param number - The number to verify. Must look like @"+15166666666".
 *      @param completion(replyTo, content, error) - A handler to call when the process is over.
 *          replyTo: the number to text the code to.
 *          content: the code to text.
 *          error: An error, if one occurred.
 */
- (void)confirmWithCompletion:(  void (^ _Nullable  )( NSString * _Nullable replyTo,  NSString * _Nullable text,  NSError * _Nullable error))confirmHandler;

/* Displays a text messaging dialog to allow the user to text in the previously specified code to the
 *  previously specified number. A handler is specified to receive callback information about
 *   the firebase JWT generated.
 * Arguments:
 *      @param replyTo: The number to send the text to. This comes straight from the handler above.
 *      @param content: The message to send. This comes straight from the handler above.
 *      @param handler: A handler to invoke when authentication is complete. If 'authenticated' is true,
 *       the number has been verified. If firebase is non-null, it is a firebase JWT token for logging in. In order to use 
 *       the firebase feature, you must configure your application's firebase settings from the portal.
 *  @return NO if the
 */
- (BOOL)authenticateWithDefaultTextMessageDialog:(NSString * _Nonnull)replyTo content:(NSString * _Nonnull)content handler:(void (^ _Nullable)(BOOL authenticated, NSString * _Nullable phoneNumber, NSString * _Nullable firebase))authHandler;

/*
 *  Returns true if the default text message dialog is available.
 */
- (BOOL)canAuthenticateWithDefaultTextMessageDialog;

/**
 * If for some reason you don't just want to show a text message dialog (perhaps telling the user to just text this in),
 * use this method. It'll start polling the server, and will call back to your function
 * when you're done.
 *      @param handler: A handler to invoke when authentication is complete. If 'authenticated' is true,
 *       the number has been verified. If firebase is non-null, it is a firebase JWT token for logging in. In order to use
 *       the firebase feature, you must configure your application's firebase settings from the portal.
 * 
 */
- (void)authenticateDoingLiterallyAnythingElse:(void (^ _Nullable)(BOOL authenticated, NSString * _Nullable phoneNumber, NSString * _Nullable firebase))authHandler;

/**
 
 */
- (void)verifyPhoneNumber:(void (^ _Nonnull)(NSString * _Nullable phoneNumber, NSString * _Nullable firebaseToken, NSError * _Nullable error))authHandler;

/**
 * The text message the user is prompted to send to verify their phone number. A random string will be appended to this.
 *  Default: "Press send to verify your phone number."
 */
@property (nonatomic, nonnull) NSString *textMessagePrompt;

@end
