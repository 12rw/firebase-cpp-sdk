// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "app_check/src/ios/app_check_ios.h"

#import "FIRApp.h"
#import "FIRAppCheck.h"
#import "FIRAppCheckProvider.h"
#import "FIRAppCheckProviderFactory.h"
#import "FIRAppCheckToken.h"

#include "app/src/app_common.h"
#include "app/src/app_ios.h"
#include "app/src/util_ios.h"
#include "app_check/src/common/common.h"
#include "app_check/src/ios/util_ios.h"
#include "firebase/app_check.h"

// Defines an iOS AppCheckProvider that wraps a given C++ Provider.
@interface CppAppCheckProvider : NSObject <FIRAppCheckProvider>

@property(nonatomic, nullable) firebase::app_check::AppCheckProvider* cppProvider;

- (id)initWithProvider:(firebase::app_check::AppCheckProvider* _Nonnull)provider;

@end

@implementation CppAppCheckProvider

- (id)initWithProvider:(firebase::app_check::AppCheckProvider* _Nonnull)provider {
  self = [super init];
  if (self) {
    self.cppProvider = provider;
  }
  return self;
}

- (void)getTokenWithCompletion:(nonnull void (^)(FIRAppCheckToken* _Nullable,
                                                 NSError* _Nullable))handler {
  auto token_callback{[handler](firebase::app_check::AppCheckToken token, int error_code,
                                const std::string& error_message) {
    NSError* ios_error = firebase::app_check::internal::AppCheckErrorToNSError(
        static_cast<firebase::app_check::AppCheckError>(error_code), error_message);
    FIRAppCheckToken* ios_token =
        firebase::app_check::internal::AppCheckTokenToFIRAppCheckToken(token);
    handler(ios_token, ios_error);
  }};
  _cppProvider->GetToken(token_callback);
}

@end

// Defines an iOS AppCheckProviderFactory that wraps a given C++ Factory.
@interface CppAppCheckProviderFactory : NSObject <FIRAppCheckProviderFactory>

@property(nonatomic, nullable) firebase::app_check::AppCheckProviderFactory* cppProviderFactory;

- (id)initWithProviderFactory:(firebase::app_check::AppCheckProviderFactory* _Nonnull)factory;

@end

@implementation CppAppCheckProviderFactory

- (id)initWithProviderFactory:(firebase::app_check::AppCheckProviderFactory* _Nonnull)factory {
  self = [super init];
  if (self) {
    self.cppProviderFactory = factory;
  }
  return self;
}

- (nullable id<FIRAppCheckProvider>)createProviderWithApp:(FIRApp*)app {
  std::string app_name = firebase::util::NSStringToString(app.name);
  firebase::App* cpp_app = firebase::app_common::FindAppByName(app_name.c_str());
  if (cpp_app == nullptr) {
    cpp_app = firebase::internal::FindPartialAppByName(app_name.c_str());
  }
  firebase::app_check::AppCheckProvider* cppProvider = _cppProviderFactory->CreateProvider(cpp_app);
  return [[CppAppCheckProvider alloc] initWithProvider:cppProvider];
}

@end

@implementation AppCheckNotificationCenterWrapper

- (id)initWith {
  NSLog(@"almostmatt - initializing app check notification center wrapper");
  self = [super init];
  if (self) {
    // TODO: almostmatt - store any state necessary
    // Probably at least store app_name
    // Could also have this wrap a single listener instead of a set of listeners
    // self->_listener = listener;
    // self->_auth = auth;
    NSLog(@"almostmatt - calling notification center AddObserver");
    [[NSNotificationCenter defaultCenter]
        addObserver:self
            selector:@selector(appCheckTokenDidChangeNotification:)
                name:FIRAppCheckAppCheckTokenDidChangeNotification
              object:nil];

  }
  return self;
}

- (void)appCheckTokenDidChangeNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    // Note: almostmatt - could check if notification.object == self.FIRApp
    // or even specify the instance of FIRApp when calling add observer
    // Note: almostmatt - the token key in this userinfo is the NSString
    // The expiration time is not available in this notification.
    // almostmatt - so to make API match, if listeners exist, call GetToken with force refresh = false
    // (though I kind of fear an infinite loop of 0-duration token refreshes)
    NSString *token = (NSString *)userInfo[kFIRAppCheckTokenNotificationKey];
    NSString *app_name = (NSString *)userInfo[kFIRAppCheckAppNameNotificationKey];
    NSLog(@"almosmtatt - appCheckTokenDidChangeNotification.");
    NSLog(@"almostmatt - for app %@", app_name);
    NSLog(@"almostmatt - new token is %@", token);
    // TODO: almostmatt - verify that this is for a relevant app
    // if (app_name)
    // TODO: almostmatt - call all token change listeners asyncronously
    // dispatch_async([FIRDatabaseQuery sharedQueue], ^{
    //   self.listener(token);
    // });
    // maybe call back to the cpp app check
    // call GetToken
    // listeners_
}

@end

namespace firebase {
namespace app_check {
namespace internal {

AppCheckInternal::AppCheckInternal(App* app) : app_(app) {
  NSLog(@"almostmatt - initializing app check instance");
  future_manager().AllocFutureApi(this, kAppCheckFnCount);
  impl_ = MakeUnique<FIRAppCheckPointer>([FIRAppCheck appCheck]);
  notification_center_wrapper_ =
      MakeUnique<AppCheckNotificationCenterWrapperPointer>(
          [[AppCheckNotificationCenterWrapper alloc] initWith]);
  // TODO: add observer for listeners
  // when token change notification happens
  // convert token, and call all listeners
  // Note: need an iOS class in order to be the NSObject that handles listening
  // Likely AppCheckInternal will hold a reference to this class
  // and this class will need to be able to call back to C++ to get the map of listeners
  // I suppose could also store the set of listeners internal to that ios class if needed
  // or it can call back to this class (though that is sort of a dependency loop)
}

AppCheckInternal::~AppCheckInternal() {
  future_manager().ReleaseFutureApi(this);
  app_ = nullptr;
  listeners_.clear();
}

::firebase::App* AppCheckInternal::app() const { return app_; }

ReferenceCountedFutureImpl* AppCheckInternal::future() {
  return future_manager().GetFutureApi(this);
}

void AppCheckInternal::SetAppCheckProviderFactory(AppCheckProviderFactory* factory) {
  CppAppCheckProviderFactory* ios_factory =
      [[CppAppCheckProviderFactory alloc] initWithProviderFactory:factory];
  [FIRAppCheck setAppCheckProviderFactory:ios_factory];
}

void AppCheckInternal::SetTokenAutoRefreshEnabled(bool is_token_auto_refresh_enabled) {
  impl().isTokenAutoRefreshEnabled = is_token_auto_refresh_enabled;
}

Future<AppCheckToken> AppCheckInternal::GetAppCheckToken(bool force_refresh) {
  SafeFutureHandle<AppCheckToken> handle =
      future()->SafeAlloc<AppCheckToken>(kAppCheckFnGetAppCheckToken);

  // __block allows handle to be referenced inside the objective C completion.
  __block SafeFutureHandle<AppCheckToken>* handle_in_block = &handle;
  [impl()
      tokenForcingRefresh:force_refresh
               completion:^(FIRAppCheckToken* _Nullable token, NSError* _Nullable error) {
                 AppCheckToken cpp_token = AppCheckTokenFromFIRAppCheckToken(token);
                 if (error != nil) {
                   NSLog(@"Unable to retrieve App Check token: %@", error);
                   int error_code = firebase::app_check::internal::AppCheckErrorFromNSError(error);
                   std::string error_message = util::NSStringToString(error.localizedDescription);

                   future()->CompleteWithResult(*handle_in_block, error_code, error_message.c_str(),
                                                cpp_token);
                   return;
                 }
                 if (token == nil) {
                   NSLog(@"App Check token is nil.");
                   future()->CompleteWithResult(*handle_in_block, kAppCheckErrorUnknown,
                                                "AppCheck GetToken returned an empty token.",
                                                cpp_token);
                   return;
                 }
                 future()->CompleteWithResult(*handle_in_block, kAppCheckErrorNone, cpp_token);
               }];
  return MakeFuture(future(), handle);
}

Future<AppCheckToken> AppCheckInternal::GetAppCheckTokenLastResult() {
  return static_cast<const Future<AppCheckToken>&>(
      future()->LastResult(kAppCheckFnGetAppCheckToken));
}

void AppCheckInternal::AddAppCheckListener(AppCheckListener* listener) {
  // TODO: almostmatt (maybe) pass the listener into notification_center_wrapper()
  NSLog(@"almostmatt - added an app check listener");
  listeners_.insert(listener);
}

void AppCheckInternal::RemoveAppCheckListener(AppCheckListener* listener) {
  NSLog(@"almostmatt - removed an app check listener");
  listeners_.erase(listener);
}

}  // namespace internal
}  // namespace app_check
}  // namespace firebase
