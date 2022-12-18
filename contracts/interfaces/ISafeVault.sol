// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title  ISafeVault
/// @author crypt0grapher
/// @notice This contract is used as a token
interface ISafeVault {

    // @notice Deposit BUSD to the vault, spending should be approved if the user is not the sender
    function deposit(uint256 _amount) external;

    // @notice Withdraw BUSD from the vault
    function withdraw(address _user, uint256 _amount) external;

    // @notice totalSupply of the vault
    function totalSupply() external view returns (uint256);

}
