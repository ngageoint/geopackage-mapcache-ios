//
//  MCKeychainUtil.swift
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/21/22.
//  Copyright © 2022 NGA. All rights reserved.
//

import Foundation
import LocalAuthentication

@objc class MCCredentials: NSObject {
    @objc var username:String = ""
    @objc var password:String = ""
}


@objc class MCKeychainUtil: NSObject {
    @objc static let shared = MCKeychainUtil()
    
    @objc func addCredentials(server: String, username: String, password: String) throws {
        let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .userPresence, nil)
        let passwordData = password.data(using: String.Encoding.utf8)!
        
        // allow a device unlock within the last 10 seconds to be used to get at keychain items
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 10
        
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: username,
                                    kSecAttrServer as String: server,
                                    kSecAttrAccessControl as String: access as Any,
                                    kSecUseAuthenticationContext as String: context,
                                    kSecValueData as String: passwordData]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw MCKeychainError(domain: "MapCache", code: 0, userInfo: ["errorCode": status])
        } // TODO: use more descriptive error
    }
    
    
    @objc func readCredentials(server: String) throws -> MCCredentials {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecUseOperationPrompt as String: "Access your password on the keychain",
                                    kSecReturnData as String: true]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            throw MCKeychainError(domain: "MapCache", code: 0, userInfo: ["errorCode": status])
        } // TODO: use more descriptive error
        
        guard let existingItem = item as? [String: Any],
              let passwordData = existingItem[kSecValueData as String] as? Data,
              let password = String(data: passwordData, encoding: String.Encoding.utf8),
              let username = existingItem[kSecAttrAccount as String] as? String
        else {
            throw MCKeychainError(domain: "MapCache", code: 0, userInfo: ["errorCode": errSecInternalError])
        }
        
        let credentials = MCCredentials()
        credentials.username = username
        credentials.password = password
        return credentials
    }
    
    
    @objc func deleteCredentials(server: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw MCKeychainError(domain: "MapCache", code: 0, userInfo: ["errorCode": errSecInternalError])
        }
        
    }
}
