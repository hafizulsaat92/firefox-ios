/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

// TODO: same comment as for SyncAuthState.swift!
private let log = XCGLogger.defaultInstance()

// The version of the account schema we persist.
let AccountSchemaVersion = 1

/// A FirefoxAccount mediates access to identity attached services.
///
/// All data maintained as part of the account or its state should be
/// considered sensitive and stored appropriately.  Usually, that means
/// storing account data in the iOS keychain.
///
/// Non-sensitive but persistent data should be maintained outside of
/// the account itself.
public class FirefoxAccount {
    /// The email address identifying the account.  A Firefox Account is uniquely identified on a particular server
    /// (auth endpoint) by its email address.
    public let email: String

    /// The auth endpoint user identifier identifying the account.  A Firefox Account is uniquely identified on a
    /// particular server (auth endpoint) by its assigned uid.
    public let uid: String

    public let configuration: FirefoxAccountConfiguration

    private let stateKeyLabel: String
    private var state: FxAState {
        didSet {
            checkpointState()
        }
    }

    public var actionNeeded: FxAActionNeeded {
        return state.actionNeeded
    }

    public init(configuration: FirefoxAccountConfiguration, email: String, uid: String, stateKeyLabel: String, state: FxAState) {
        self.email = email
        self.uid = uid
        self.configuration = configuration
        self.stateKeyLabel = stateKeyLabel
        self.state = state
        checkpointState()
    }

    public class func fromConfigurationAndJSON(configuration: FirefoxAccountConfiguration, data: JSON) -> FirefoxAccount? {
        if let email = data["email"].asString {
            if let uid = data["uid"].asString {
                if let sessionToken = data["sessionToken"].asString?.hexDecodedData {
                    if let keyFetchToken = data["keyFetchToken"].asString?.hexDecodedData {
                        if let unwrapkB = data["unwrapBKey"].asString?.hexDecodedData {
                            let verified = data["verified"].asBool ?? false
                            return FirefoxAccount.fromConfigurationAndParameters(configuration,
                                email: email, uid: uid, verified: verified,
                                sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
                        }
                    }
                }
            }
        }
        return nil
    }

    public class func fromConfigurationAndLoginResponse(configuration: FirefoxAccountConfiguration,
            response: FxALoginResponse, unwrapkB: NSData) -> FirefoxAccount {
        return FirefoxAccount.fromConfigurationAndParameters(configuration,
            email: response.remoteEmail, uid: response.uid, verified: response.verified,
            sessionToken: response.sessionToken, keyFetchToken: response.keyFetchToken, unwrapkB: unwrapkB)
    }

    private class func fromConfigurationAndParameters(configuration: FirefoxAccountConfiguration,
            email: String, uid: String, verified: Bool,
            sessionToken: NSData, keyFetchToken: NSData, unwrapkB: NSData) -> FirefoxAccount {
        var state: FxAState! = nil
        if !verified {
            let now = NSDate.now()
            state = EngagedBeforeVerifiedState(knownUnverifiedAt: now,
                lastNotifiedUserAt: now,
                sessionToken: sessionToken,
                keyFetchToken: keyFetchToken,
                unwrapkB: unwrapkB
            )
        } else {
            state = EngagedAfterVerifiedState(
                sessionToken: sessionToken,
                keyFetchToken: keyFetchToken,
                unwrapkB: unwrapkB
            )
        }

        let account = FirefoxAccount(
            configuration: configuration,
            email: email,
            uid: uid,
            stateKeyLabel: Bytes.generateGUID(),
            state: state
        )
        return account
    }

    public func asDictionary() -> [String: AnyObject] {
        var dict: [String: AnyObject] = [:]
        dict["version"] = AccountSchemaVersion
        dict["email"] = email
        dict["uid"] = uid
        dict["configurationLabel"] = configuration.label.rawValue
        dict["stateKeyLabel"] = stateKeyLabel
        return dict
    }

    public class func fromDictionary(dictionary: [String: AnyObject]) -> FirefoxAccount? {
        if let version = dictionary["version"] as? Int {
            if version == AccountSchemaVersion {
                return FirefoxAccount.fromDictionaryV1(dictionary)
            }
        }
        return nil
    }

    private class func labelAndStateFromKeychain(label: String?) -> (String, FxAState) {
        if let l = label {
            if let s = KeychainWrapper.stringForKey("account.state." + l) {
                if let t = stateFromJSON(JSON.parse(s)) {
                    log.info("Read Account State from Keychain with label account.state.\(l)")
                    return (l, t)
                } else {
                    log.warning("Found Account State in Keychain with label account.state.\(l), but could not parse it.")
                }
            } else {
                log.warning("Did not find Account State in Keychain with label account.state.\(l).")
            }
        } else {
            log.warning("Did not find Account State label in Keychain.")
        }
        // Fall through to Separated.
        log.warning("Failed to read Account State from Keychain; moving account to Separated.")
        return (Bytes.generateGUID(), SeparatedState())
    }

    private class func fromDictionaryV1(dictionary: [String: AnyObject]) -> FirefoxAccount? {
        var configurationLabel: FirefoxAccountConfigurationLabel? = nil
        if let rawValue = dictionary["configurationLabel"] as? String {
            configurationLabel = FirefoxAccountConfigurationLabel(rawValue: rawValue)
        }
        if let
            configurationLabel = configurationLabel,
            email = dictionary["email"] as? String,
            uid = dictionary["uid"] as? String {
                let (stateKeyLabel, state) = labelAndStateFromKeychain(dictionary["stateKeyLabel"] as? String)
                return FirefoxAccount(
                    configuration: configurationLabel.toConfiguration(),
                    email: email, uid: uid,
                        stateKeyLabel: stateKeyLabel,
                        state: state)
        }
        return nil
    }

    public func checkpointState() {
        log.info("Storing Account State in Keychain with label account.state.\(stateKeyLabel)")
        // TODO: PII logging.
        let jsonString = state.asJSON().toString(pretty: false)
        KeychainWrapper.setString(jsonString, forKey: "account.state." + stateKeyLabel)
    }

    public enum AccountError: Printable, ErrorType {
        case NotMarried

        public var description: String {
            switch self {
            case NotMarried: return "Not married."
            }
        }
    }

    func advance() -> Deferred<FxAState> {
        let client = FxAClient10(endpoint: configuration.authEndpointURL)
        let stateMachine = FxALoginStateMachine(client: client)
        let now = NSDate.now()
        return stateMachine.advanceFromState(state, now: now).map { newState in
            self.state = newState
            return newState
        }
    }

    public func marriedState() -> Deferred<Result<MarriedState>> {
        return advance().map { newState in
            if newState.label == FxAStateLabel.Married {
                if let married = newState as? MarriedState {
                    return Result(success: married)
                }
            }
            return Result(failure: AccountError.NotMarried)
        }
    }

    public func syncAuthState() -> SyncAuthState {
        let url = configuration.sync15Configuration.tokenServerEndpointURL
        return SyncAuthState(account: self, tokenServerURL: url)
    }
}
