// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title  ISafeVault
/// @author crypt0grapher
/// @notice Safe Yield Vault depositing to the third-party yield farms
interface ISafeVault {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    // @notice deposit stable coin  to the vault from the sender
    // @param _amount amount of stable coin  to deposit
    function deposit(uint256 _amount) external;

    // @notice Withdraw stable coin  from the vault to the receiver from the function caller (msg.sender)
    // @param _user user to send tokens to, withdrawn from the sender
    // @param _amount amount of stable coin  to withdraw
    function withdraw(address _user, uint256 _amount) external;

    // @notice totalSupply of the vault, total amount of the stablecoin in the vault, including deposits and other tokens transferred to the vault
    // @return total supply of the vault
    function totalSupply() external view returns (uint256);

    // @notice totalSupply of the vault
    // @return total supply of the vault
    function deposited() external view returns (uint256);

}
