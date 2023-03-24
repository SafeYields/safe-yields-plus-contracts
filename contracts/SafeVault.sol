// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "./interfaces/ISafeVault.sol";
import "./Owned.sol";

/// @title  Safe Vault
/// @author crypt0grapher
/// @notice This contract is responsible for the stablecoin pool: mainly deposit/withdrawal and farms management
contract SafeVault is ISafeVault, Proxied, Owned, ReentrancyGuard {
    IERC20 public usd;
    uint256 public deposited;
    mapping(address => uint256) public balances;
    /// @notice only Safe Token can withdraw tokens from the vault, when users sell SAFE
    address public safeToken;

    modifier onlyOwner() {
        require(msg.sender == _getOwner(), "SafeVault: only owner");
        _;
    }

    function initialize(address _usd) public proxied {
        usd = IERC20(_usd);
    }

    constructor(address _usd) {
        initialize(_usd);
    }

    function setSafeToken(address _safeToken) external onlyOwner {
        safeToken = _safeToken;
    }

    /// @dev total supply, used to determine the price of the SAFE token, deposited on SAFE purchase + transferred to the vault
    function totalSupply() external view returns (uint256) {
        return usd.balanceOf(address(this));
    }

    /// @dev Deposit stablecoin to the vault, the total supply of the vault includes not only tokens deposited by users, but also tokens transferred  to the vault
    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "SafeVault: amount must be greater than 0");
        balances[msg.sender] += _amount;
        deposited += _amount;
        usd.transferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(address _receiver, uint256 _amount) external nonReentrant {
        /// @dev we're allowing withdrawals only to Safe Token, not any user, not even admin is allowed to withdraw from the vault.
        require(msg.sender == safeToken, "SafeVault: only safe token");
        require(_amount > 0, "SafeVault: amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "SafeVault: user balance is less than amount to withdraw");
        balances[msg.sender] -= _amount;
        deposited -= _amount;
        usd.transfer(_receiver, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /// @dev this one is used to recover tokens sent to the vault by mistake, including both SAFE and USD ones
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(_getOwner(), tokenAmount);
    }

    function recoverETH() external onlyOwner {
        payable(_getOwner()).transfer(address(this).balance);
    }

}
