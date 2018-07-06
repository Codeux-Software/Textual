/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2017, 2018 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "ICLPluginProtocol.h"
#import "ICLPluginManagerPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface ICLPluginManager ()
@property (nonatomic, assign) BOOL pluginsLoaded;
@property (nonatomic, copy) NSArray<NSBundle *> *loadedPlugins;
@property (nonatomic, copy, nullable) NSArray<Class> *loadedModules;
@end

@implementation ICLPluginManager

+ (ICLPluginManager *)sharedPluginManager
{
	static ICLPluginManager *sharedSelf = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedSelf = [[self alloc] init];
	});

	return sharedSelf;
}

- (NSURL *)_bundledPluginsURL
{
	return [RZMainBundle() URLForResource:@"Extensions" withExtension:nil];
}

- (void)loadPluginsAtLocations:(NSArray<NSURL *> *)pluginLocations
{
	NSParameterAssert(pluginLocations != nil);

	NSAssert((self.pluginsLoaded == NO), @"Plugins already loaded");

	pluginLocations =
	[pluginLocations arrayByAddingObject:[self _bundledPluginsURL]];

	NSMutableArray<NSBundle *> *loadedPlugins = [NSMutableArray array];

	for (NSURL *pluginLocation in pluginLocations) {
		NSString *pluginPath = pluginLocation.path;

		NSArray *plugins = [self _loadPluginsAtPath:pluginPath];

		if (plugins) {
			[loadedPlugins addObjectsFromArray:plugins];
		}
	}

	self.loadedPlugins = loadedPlugins;

	self.pluginsLoaded = YES;

	[self _populateModules];
}

- (nullable NSArray<NSBundle *> *)_loadPluginsAtPath:(NSString *)pluginsPath
{
	NSParameterAssert(pluginsPath != nil);

	NSMutableArray<NSBundle *> *loadedPlugins = [NSMutableArray array];

	NSError *listedFilesError;
	
	NSArray *listedFiles = [RZFileManager() contentsOfDirectoryAtPath:pluginsPath error:&listedFilesError];

	if (listedFiles == nil) {
		LogToConsoleError("Failed to list plugins: %@",
			listedFilesError.localizedDescription);

		return nil;
	}

	for (NSString *file in listedFiles) {
		if ([file hasSuffix:@".mediaPlugin"] == NO) {
			continue;
		}

		NSString *filePath = [pluginsPath stringByAppendingPathComponent:file];

		NSBundle *bundle = [self _loadPluginAtPath:filePath];

		if (bundle == nil) {
			continue;
		}

		[loadedPlugins addObject:bundle];
	}

	return loadedPlugins;
}

- (nullable NSBundle *)_loadPluginAtPath:(NSString *)pluginPath
{
	NSParameterAssert(pluginPath != nil);

	/* Load bundle */
	NSBundle *bundle = [NSBundle bundleWithPath:pluginPath];

	if (bundle == nil) {
		return nil;
	}

	/* Check for a principal class */
	Class principalClass = bundle.principalClass;

	if (principalClass == NULL) {
		LogToConsoleError("Failed to load bundle '%@' because of NULL principal class", bundle.bundleURL);

		return nil;
	}

	/* Check for conformity */
	if ([principalClass conformsToProtocol:@protocol(ICLPluginProtocol)] == NO) {
		LogToConsoleError("Failed to load bundle '%@' because it does not conform to the ICLPluginProtocol protocol", bundle.bundleURL);

		return nil;
	}

	/* Success */
	return bundle;
}

- (void)_populateModules
{
	NSArray *loadedPlugins = self.loadedPlugins;

	if (loadedPlugins.count == 0) {
		LogToConsoleInfo("No plugins to load modules from");

		return;
	}

	NSMutableArray<Class> *loadedModules = [NSMutableArray array];

	for (NSBundle *plugin in loadedPlugins) {
		NSArray *modules = [self _populateModulesForPlugin:plugin];

		[loadedModules addObjectsFromArray:modules];
	}

	self.loadedModules = loadedModules;
}

- (NSArray<Class> *)_populateModulesForPlugin:(NSBundle *)plugin
{
	NSParameterAssert(plugin != nil);

	/* We have already proven in -_loadPluginAtPath: that the plugin
	 conforms to everything so we don't have to perform validation. */
	Class <ICLPluginProtocol> principalClass = plugin.principalClass;

	return [principalClass performSelector:@selector(modules)];
}

- (NSArray<Class> *)modules
{
	NSArray *modules = self.loadedModules;

	if (modules == nil) {
		return @[];
	}

	return modules;
}

@end

NS_ASSUME_NONNULL_END
