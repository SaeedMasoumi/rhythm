#import "RhythmPlugin.h"
#if __has_include(<rhythm/rhythm-Swift.h>)
#import <rhythm/rhythm-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "rhythm-Swift.h"
#endif

@implementation RhythmPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftRhythmPlugin registerWithRegistrar:registrar];
}
@end
