// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title  Safe NFT
/// @author crypt0grapher
/// @notice Safe Yields NFT token based on ERC1155 standard, id [0..3] represents one of the 4 tiers

contract Owned {
    /// @dev this is getting the owner from the proxy contract, the proxy contract is ERC-173 compliant and support transferOwnership
    /// @dev service function used by children contracts which are at least SafeVault.sol and SafeToken.sol
    function _getOwner() internal view returns (address adminAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            adminAddress := sload(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)
        }
    }
}
