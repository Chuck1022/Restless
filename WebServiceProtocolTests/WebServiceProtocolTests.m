//
//  WebServiceProtocolTests.m
//  WebServiceProtocolTests
//
//  Created by Nate Petersen on 9/1/15.
//  Copyright © 2015 Digital Rickshaw. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GitHubService.h"
#import <OHHTTPStubs.h>
#import "GitHubRepo.h"

@import WebServiceProtocol;

@interface WebServiceProtocolTests : XCTestCase

@end

@implementation WebServiceProtocolTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
	[OHHTTPStubs removeAllStubs];
	
    [super tearDown];
}

- (void)testProtocolCreation {
	DRRestAdapter* ra = [DRRestAdapter restAdapterWithBlock:^(DRRestAdapterBuilder *builder) {
		builder.endPoint = [NSURL URLWithString:@"https://api.github.com"];
		builder.bundle = [NSBundle bundleForClass:[DRRestAdapter class]];
	}];
	
	NSObject<GitHubService>* service = [ra create:@protocol(GitHubService)];
	XCTAssertNotNil(service);
	XCTAssertTrue([service respondsToSelector:@selector(listRepos:callback:)]);
	XCTAssertTrue([service.class conformsToProtocol:@protocol(GitHubService)]);
}

- (void)testProtocolEndToEndSuccess {
	[OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
		return [request.URL.host isEqualToString:@"api.github.com"];
	} withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
		NSString* fixture = OHPathForFile(@"listReposResponse.json", self.class);
		return [OHHTTPStubsResponse responseWithFileAtPath:fixture
												statusCode:200
												   headers:@{@"Content-Type":@"application/json"}];
	}];
	
	
	DRRestAdapter* ra = [DRRestAdapter restAdapterWithBlock:^(DRRestAdapterBuilder *builder) {
		builder.endPoint = [NSURL URLWithString:@"https://api.github.com"];
		builder.bundle = [NSBundle bundleForClass:[DRRestAdapter class]];
	}];
	
	NSObject<GitHubService>* service = [ra create:@protocol(GitHubService)];
	
	XCTestExpectation *callBackExpectation = [self expectationWithDescription:@"callback"];
	
	NSURLSessionDataTask* task = [service listRepos:@"natep" callback:^(NSArray *result, NSURLResponse *response, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			XCTAssertNil(error);
			XCTAssertNotNil(result);
			XCTAssertTrue([result isKindOfClass:[NSArray class]]);
			XCTAssertEqual([result count], 4);
			XCTAssertTrue([[result firstObject] isKindOfClass:[GitHubRepo class]]);
			GitHubRepo* repo = [result firstObject];
			XCTAssertEqualObjects(repo.repoId, @(32614184));
			
			[callBackExpectation fulfill];
		});
	}];
	
	[task resume];
	
	[self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
		if (error) {
			NSLog(@"%@", error);
		}
	}];
}

- (void)testProtocolEndToEndFailure {
	[OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
		return [request.URL.host isEqualToString:@"api.github.com"];
	} withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
		return [OHHTTPStubsResponse responseWithError:[NSError errorWithDomain:NSURLErrorDomain
																		  code:kCFURLErrorBadServerResponse
																	  userInfo:nil]];
	}];
	
	
	DRRestAdapter* ra = [DRRestAdapter restAdapterWithBlock:^(DRRestAdapterBuilder *builder) {
		builder.endPoint = [NSURL URLWithString:@"https://api.github.com"];
		builder.bundle = [NSBundle bundleForClass:[DRRestAdapter class]];
	}];
	
	NSObject<GitHubService>* service = [ra create:@protocol(GitHubService)];
	
	XCTestExpectation *callBackExpectation = [self expectationWithDescription:@"callback"];
	
	NSURLSessionDataTask* task = [service listRepos:@"natep" callback:^(NSArray *result, NSURLResponse *response, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			XCTAssertNotNil(error);
			
			[callBackExpectation fulfill];
		});
	}];
	
	[task resume];
	
	[self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
		if (error) {
			NSLog(@"%@", error);
		}
	}];
}

@end
