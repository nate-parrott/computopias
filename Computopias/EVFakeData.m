//
//  EVFakeData.m
//  Elastic
//
//  Created by Nate Parrott on 7/13/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EVFakeData.h"

@implementation EVFakeData

- (instancetype)init {
    self = [super init];
    self.shortText = [[self class] fakeSentence];
    self.longText = [[self class] fakeParagraph];
    self.color = [UIColor colorWithHue:(rand() % 1000)/1000.0 saturation:0.8 brightness:0.8 alpha:1];
    self.url = [NSURL URLWithString:@"https://google.com"];
    self.word = [[[self class] fakeSentence] componentsSeparatedByString:@" "].firstObject;
    self.identifier = [[NSUUID UUID] UUIDString];
    return self;
}

+ (NSString *)fakeSentence {
    static NSArray *words;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *w1 = [@"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur dapibus ex velit, a ultrices risus dignissim vitae. Nullam vitae massa pellentesque, ullamcorper justo id, commodo felis. Quisque convallis hendrerit consequat. Integer sit amet lobortis urna. Nunc est sem, accumsan in sollicitudin vitae, consequat vel leo. Donec finibus malesuada mi. Donec porta mollis elementum. Vivamus lacinia, ex et faucibus sollicitudin, libero augue euismod tellus, et gravida est justo eget nunc. Sed dapibus felis mattis pharetra volutpat. Nulla tincidunt leo et ultrices luctus. Ut varius mollis vulputate. Mauris porttitor, risus vel viverra malesuada, sapien ex auctor diam, eu hendrerit augue turpis et augue. Integer ultricies viverra odio sit amet viverra. Nam scelerisque tellus non dolor fringilla, in faucibus libero pharetra." componentsSeparatedByString:@" "];
        NSMutableArray *allWords = [NSMutableArray new];
        for (NSString *word in w1) {
            NSString *w2 = [word stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (w2.length > 0) {
                [allWords addObject:w2.lowercaseString];
            }
        }
        words = allWords;
    });
    NSMutableArray *pickedWords = [NSMutableArray new];
    NSInteger length = rand() % 20 + 1;
    for (NSInteger i=0; i<length; i++) {
        NSString *word = words[rand() % words.count];
        if (i == 0) word = [[[word substringToIndex:1] uppercaseString] stringByAppendingString:[word substringFromIndex:1]];
        [pickedWords addObject:word];
    }
    return [pickedWords componentsJoinedByString:@" "];
}

+ (NSString *)fakeParagraph {
    NSInteger length = rand() % 5 + 1;
    NSMutableArray *sentences = [NSMutableArray new];
    for (NSInteger i=0; i<length; i++) {
        [sentences addObject:[self fakeSentence]];
    }
    return [sentences componentsJoinedByString:@". "];
}

+ (NSArray *)getFakeData:(NSInteger)n {
    NSMutableArray *data = [NSMutableArray new];
    for (NSInteger i=0; i<n; i++) {
        [data addObject:[EVFakeData new]];
    }
    return data;
}

@end
