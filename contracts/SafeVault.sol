// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "./interfaces/ISafeVault.sol";

/// @title  Safe Vault
/// @author crypt0grapher
/// @notice This contract is responsible for $USDC pool: mainly deposit/withdrawal and farms management
contract SafeVault is ISafeVault, Proxied, ReentrancyGuard {
    IERC20 public usd;
    uint256 public deposited;
    mapping(address => uint256) public balances;

    function initialize(address _usd) public proxied {
        usd = IERC20(_usd);
    }

    constructor(address _usd) {
        initialize(_usd);
    }

    function totalSupply() external view returns (uint256) {
        return usd.balanceOf(address(this));
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "SafeVault: amount must be greater than 0");
        balances[msg.sender] += _amount;
        deposited += _amount;
        usd.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(address _receiver, uint256 _amount) external nonReentrant {
        require(_amount > 0, "SafeVault: amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "SafeVault: user balance is less than amount to withdraw");
        balances[msg.sender] -= _amount;
        deposited -= _amount;
        usd.transfer(_receiver, _amount);
    }

}
