// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "./interfaces/ISafeVault.sol";

/// @title  Safe Vault
/// @author crypt0grapher
/// @notice This contract is responsible for $BUSD pool: mainly deposit/withdrawal and farms management
contract SafeVault is ISafeVault, Proxied {
    IERC20 stableCoin;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;

    function initialize(address _stableCoin) public proxied {
        stableCoin = IERC20(_stableCoin);
    }

    constructor(address _stableCoin) public {
        initialize(_stableCoin);
    }

    function deposit(address _user, uint256 _amount) external {
        require(_amount > 0, "SafeVault: amount must be greater than 0");
        balances[_user] += _amount;
        totalSupply += _amount;
        stableCoin.transferFrom(_user, address(this), _amount);
    }

    function withdraw(address _receiver, uint256 _amount) external {
        require(_amount > 0, "SafeVault: amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "SafeVault: user balance is less than amount to withdraw");
        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
        stableCoin.transfer(_receiver, _amount);
    }

}
