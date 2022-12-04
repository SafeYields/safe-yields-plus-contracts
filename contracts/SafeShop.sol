// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./interfaces/ISafeToken.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";

/// @title  SafeShop
/// @author crypt0grapher
/// @notice This contract is used to buy and sell tokens
contract SafeShop is Proxied {
    ISafeToken public token;

    constructor(address _safeToken) public {
        token = ISafeToken(_safeToken);
    }

    function price() public view returns (uint256) {
        return 1;
    }

    function buy(uint256 amount) public payable {
        require(msg.value == amount * price(), "SafeShop:insufficient-amount");

    }

    function sell(uint256 amount) public {
        payable(msg.sender).transfer(amount * price());
    }

}
