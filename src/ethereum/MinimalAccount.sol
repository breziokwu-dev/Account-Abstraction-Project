// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract MinimalAccount is IAccount, Ownable {
    uint256 ourNonce = 0;
    IEntryPoint private immutable i_entryPoint;

    error MinimalAccount__NotFromEntryPoint();

    modifier requireFromEntryPoint() {
        if(msg.sender != address(i_entryPoint)) {
            revert MinimalAccount__NotFromEntryPoint();
        }
        _;
    }

    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entryPoint);
    }

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds) external override returns (uint256 validationData) {
        // This is a minimal implementation, so we don't perform any actual validation.
        // In a real implementation, you would check signatures, nonce, and other conditions here.
        validationData = _validateSignature(userOp, userOpHash);
        _payPrefund(missingAccountFunds);
        return validationData;
    }

    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash) internal view returns (uint256 validationData) {
        // Minimal signature validation logic
        // In a real implementation, you would verify the signature against the userOpHash and the owner's address.
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED; // Signature validation failed
        }
        return SIG_VALIDATION_SUCCESS; // Signature validation succeeded
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success); // Ignore success/failure of the transfer, as per the minimal implementation
        }
    }

    function getEntryPoint() external view returns (address) {
        return address(i_entryPoint);
    }
}