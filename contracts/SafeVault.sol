// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";

/// @title  Safe Vault
/// @author crypt0grapher
/// @notice This contract is responsible for $BUSD pool: mainly deposit/withdrawal and farms management
contract SafeVault is Proxied {
    IERC20 stableCoin;
    uint256 public totalSupply;

    function initialize(address _stableCoin) public proxied {
        stableCoin = IERC20(_stableCoin);
    }

    constructor(address _stableCoin) public {
        initialize(_stableCoin);
    }

    function deposit(address _user, uint256 _amount) external {
        totalSupply += _amount;
        stableCoin.transferFrom(_user, address(this), _amount);
    }

    function withdraw(address _user, uint256 _amount) external {
        totalSupply -= _amount;
        stableCoin.transfer(_user, _amount);
    }

}
