// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";

/// @title  Safe Vault
/// @author crypt0grapher
/// @notice This contract is responsible for $BUSD pool: mainly deposit/withdrawal and farms management
contract SafeVault is Proxied {
    address public shop;

    constructor(address _safeShop) public {
        shop = _safeShop;
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
