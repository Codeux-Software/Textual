// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "IRCServerKeychainDataModel.h"

@implementation IRCServerKeychainDataModel

+ (NSString *)nicknamePassword:(NSString *)currentPassword 
					  withGUID:(NSString *)guid 
					   andCUID:(NSInteger)cuid
{
	if ([currentPassword isEmpty]) {
		NSString *knickPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (NickServ)"
															 withItemKind:@"application password" 
															  forUsername:nil 
															  serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", guid]
														withLegacySupport:NO];
		
		if ([knickPassword isEmpty]) { 
			knickPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual Keychain (NickServ)"
													   withItemKind:@"application password" 
														forUsername:nil 
														serviceName:[NSString stringWithFormat:@"textual.clients.cuid.%i", cuid]
												  withLegacySupport:YES];
		}
		
		if (knickPassword) currentPassword = knickPassword;		
	}
	
	return currentPassword;
}

+ (void)setNicknamePassword:(NSString *)password 
				   withHost:(NSString *)host 
					andGUID:(NSString *)guid 
{
	if ([password isEmpty]) {
		[AGKeychain deleteKeychainItem:@"Textual (NickServ)"
						  withItemKind:@"application password"
						   forUsername:nil
						   serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", guid]];
		
	} else {
		[AGKeychain modifyOrAddKeychainItem:@"Textual (NickServ)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:password
								withComment:host
								serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", guid]];
	}
}

+ (NSString*)serverPassword:(NSString *)currentPassword
				   withGUID:(NSString *)guid 
					andCUID:(NSInteger)cuid
{
	if ([currentPassword isEmpty]) {
		NSString *kPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (Server Password)"
														 withItemKind:@"application password" 
														  forUsername:nil 
														  serviceName:[NSString stringWithFormat:@"textual.server.%@", guid]
													withLegacySupport:NO];
		
		if ([kPassword isEmpty]) {
			kPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual Keychain (Server Password)"
												   withItemKind:@"application password" 
													forUsername:nil
													serviceName:[NSString stringWithFormat:@"textual.clients.cuid.%i", cuid]
											  withLegacySupport:YES];
		}
		
		if (kPassword) currentPassword = kPassword;
	}
	
	return currentPassword;
}

+ (void)setServerPassword:(NSString *)password 
				 withHost:(NSString *)host
				  andGUID:(NSString *)guid 
{
	if ([password isEmpty]) {
		[AGKeychain deleteKeychainItem:@"Textual (Server Password)"
						  withItemKind:@"application password"
						   forUsername:nil
						   serviceName:[NSString stringWithFormat:@"textual.server.%@", guid]];		
	} else {
		[AGKeychain modifyOrAddKeychainItem:@"Textual (Server Password)"
							   withItemKind:@"application password"
								forUsername:nil
							withNewPassword:password
								withComment:host
								serviceName:[NSString stringWithFormat:@"textual.server.%@", guid]];			
	}
}

+ (void)destroyKeychains:(NSString *)guid 
{
	[AGKeychain deleteKeychainItem:@"Textual (Server Password)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.server.%@", guid]];
	
	[AGKeychain deleteKeychainItem:@"Textual (NickServ)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", guid]];
}

@end