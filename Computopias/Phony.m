//
//  Pushy.m
//  Phony Example
//
//  Created by Justin Brower on 3/28/16.
//  Copyright © 2016 Pushy. All rights reserved.
//

#import "Phony.h"
#import <MessageUI/MessageUI.h>
#import <Security/Security.h>

@implementation Phony
@synthesize handler;

static Phony *__sharedPhony = nil;

/* Initializes phony for a specific application */
+ (void)initWithAppKey:(NSString *)appKey secret:(NSString *)secret {
    if (__sharedPhony == nil) {
        __sharedPhony = [[Phony alloc] initWithApplicationKey:appKey secret:secret];
    }
}

/* Returns the shared pushy manager thing */
+ (instancetype)sharedPhony {
    return __sharedPhony;
}

- (id)initWithApplicationKey:(NSString *)key secret:(NSString *)secret {
    
    if (self = [super init]) {
        applicationKey = key;
        applicationSecret = secret;
        self.textMessagePrompt = @"Press send to verify your phone number.";
    }
    
    return self;
}

- (void)confirmWithCompletion:(void (^)(NSString *replyTo, NSString *text, NSError *error))confirmHandler {
    NSString *token = [[self class] generateToken];
    
    NSString *request = [[NSString stringWithFormat:@"https://pushharder-1251.appspot.com/phony/propose?token=%@&key=%@&secret=%@", token, applicationKey, applicationSecret] stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:request] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
       
        NSError *e;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&e];
        
        #ifdef PUSHY_DEBUG
        NSString *responseText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"[%@] Got response: %@", request, responseText);
        #endif
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (e != nil) {
                // error parsing response.
                if (confirmHandler != nil) {
                    confirmHandler(nil, nil, e);
                }
                
                return;
            }
            
            if (result == nil && error != nil) {
                if (confirmHandler != nil) {
                    confirmHandler(nil, nil, error);
                }
                
                return;
            }
            
            if (result == nil) {
                if (confirmHandler != nil) {
                    confirmHandler(nil, nil, [NSError errorWithDomain:@"com.pushy.phony" code:8 userInfo:@{@"error" : @"Couldn't parse server response."}]);
                }
                
                return;
            }
            
            if (result[@"success"]) {
                NSString *replyTo = result[@"replyTo"];
                NSString *replySecret = result[@"secret"];
                
                // set up state for the next phase of authentication.
                current_token_secret = replySecret;
                current_token = token;
                
                NSString *text = token; // [NSString stringWithFormat:@"%@:%@:%@", applicationKey, token, replySecret];
                return confirmHandler(replyTo, text, nil);
            } else {
                if (confirmHandler != nil) {
                    confirmHandler(nil, nil, [NSError errorWithDomain:@"com.pushy.phony" code:8 userInfo:@{@"error" : result[@"error"]}]);
                }
                return;
            }
        });
    }] resume];
    
    
}

- (UIViewController *)viewControllerForModalPresentation {
    UIViewController *vc = [UIApplication sharedApplication].windows.firstObject.rootViewController;
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
    }
    return vc;
}

/* Attempts to confirm the phone number by having the user text in a code. Convenience
 *  method to allow specification of the number of retries.
 */
- (BOOL)authenticateWithDefaultTextMessageDialog:(NSString * _Nonnull)replyTo content:(NSString * _Nonnull)content handler:(void (^ _Nullable)(BOOL authenticated, NSString * _Nullable phoneNumber, NSString * _Nullable firebase))authHandler {

    // make sure we're in the correct state.
    if (current_token_secret == nil || current_token == nil) {
        return NO;
    }
    
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *vc = [[MFMessageComposeViewController alloc] init];
        [vc setRecipients:@[replyTo]];
        [vc setBody:[NSString stringWithFormat:@"%@ %@", self.textMessagePrompt, current_token]];
        [vc setMessageComposeDelegate:self];
        self.handler = authHandler;
        [[self viewControllerForModalPresentation] presentViewController:vc animated:YES completion:nil];
        return YES;
    } else {
        return NO;
    }
}

/* Generates a random string */
- (NSString *)generateRandomString:(int)len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:len];
    
    for (int i = 0; i < len; i++) {
        [randomString appendFormat:@"%C", [letters characterAtIndex:arc4random() % [letters length]]];
    }
    
    return randomString;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    if (pollTimer) {
        [pollTimer invalidate];
    }
    if (result == MessageComposeResultSent) {
        // start polling the server for updates
        [self performSelector:@selector(beginPolling:) withObject:nil afterDelay:MIN_DELAY];
    }
    
    [[controller presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (void)beginPolling:(id)sender {
    pollCount = 0;
    polling = NO;
    pollTimer = [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(poll:) userInfo:nil repeats:YES];
}

- (void)poll:(id)sender {
    if (polling) {
        return;
    }
    
    polling = YES;
    pollCount++;
    
    if (pollCount > MAX_POLL) {
        // too many polls
        if (handler) {
            current_token = nil;
            current_token_secret = nil;
            current_phone_number = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO, nil, nil);
            });
        }
    } else {
        // try a poll
        NSString *url_str = [[NSString stringWithFormat:@"https://pushharder-1251.appspot.com/phony/poll?token=%@&key=%@&secret=%@", current_token, applicationKey, current_token_secret] stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
        
        NSURL *url = [NSURL URLWithString:url_str];
        [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            NSError *e;
            NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&e];
            
            #ifdef PUSHY_DEBUG
            NSString *responseText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"[Pushy] Response: %@", responseText);
            #endif
            if (!e) {
                // interpret the response
                if ([responseObject[@"claimed"] boolValue]) {
                    [pollTimer invalidate];
                    NSString *firebaseToken = [responseObject objectForKey:@"firebase_token"];
                    if (![firebaseToken isKindOfClass:[NSString class]]) firebaseToken = nil;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        handler(YES, [responseObject objectForKey:@"phone_number"], firebaseToken);
                    });
                }
            }
            #ifdef PUSHY_DEBUG
            else {
                NSLog(@"[Pushy] (attempt #%d) Error - %@", pollCount, e);
            }
            #endif
            // release the boolean lock
            polling = NO;
        }] resume];
    }
}

- (BOOL)canAuthenticateWithDefaultTextMessageDialog {
    return [MFMessageComposeViewController canSendText];
}

- (void)authenticateDoingLiterallyAnythingElse:(void (^ _Nullable)(BOOL authenticated, NSString * _Nullable phoneNumber, NSString * _Nullable firebase))authHandler {
    handler = authHandler;
    [self performSelector:@selector(beginPolling:) withObject:nil afterDelay:MIN_DELAY];
}

- (void)verifyPhoneNumber:(void (^)(NSString * _Nullable phoneNumber, NSString * _Nullable firebaseToken, NSError * _Nullable error))authHandler {
    [self confirmWithCompletion:^(NSString * _Nullable replyTo, NSString * _Nullable text, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (replyTo && text && !error) {
                [self authenticateWithDefaultTextMessageDialog:replyTo content:text handler:^(BOOL authenticated, NSString * _Nullable phoneNumber, NSString * _Nullable firebase) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        authHandler(phoneNumber, firebase, nil);
                    });
                }];
            } else {
                authHandler(nil, nil, error);
            }
        });
    }];
}

+ (NSString *)generateToken {
    return [self randomStringOfLength:12 insertDashes:YES];
}

+ (NSString *)randomStringOfLength:(int)length insertDashes:(BOOL)dashes {
    int* randInts = malloc(sizeof(int)*length);
    SecRandomCopyBytes(kSecRandomDefault, sizeof(int)*length, (void*)randInts);
    NSString* pickChars = [NSString stringWithFormat:@"abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ0123456789"];
    NSMutableString* string = [NSMutableString new];
    for (int i=0; i<length; i++) {
        NSString* c = [pickChars substringWithRange:NSMakeRange(randInts[i]%pickChars.length, 1)];
        [string appendString:c];
        if (i+1 < length && dashes && (i+1)%4==0) {
            [string appendString:@"-"];
        }
    }
    free(randInts);
    return string;
}


@end
