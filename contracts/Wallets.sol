// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract Wallets {
    uint256 constant HUNDRED_PERCENT = 10000;

    /// @dev total wallets on the protocol, see Wallets enum
    uint256 public constant WALLETS = 2;
    // @notice token wallets configuration
    address[WALLETS] public wallets;

    /// @notice protocol wallets for easy enumeration,
    /// @dev the order is extremely important once deployed, see configuration scripts
    // rewards distribution is the balance of SafeNFT,
    enum WalletsUsed {
        InvestmentPool,
        Management
    }

    function _setWallets(address[WALLETS] memory _wallets) internal {
        wallets = _wallets;
    }

    // @notice Distribution percentages, multiplied by 10000, (25 stands for 0.25%)
    function _distribute(IERC20 _paymentToken, uint256 _amount, uint256[WALLETS] storage walletPercentageDistribution) internal returns (uint256) {
        console.log("Distributing %s", _amount);
        uint256 amountPaid = 0;
        for (uint256 i = 0; i < WALLETS; i++) {
            uint256 amount = (_amount * walletPercentageDistribution[i]) / HUNDRED_PERCENT;
            _paymentToken.transfer(wallets[i], amount);
            amountPaid += amount;
        }
        console.log("Distributed %s", amountPaid);
        return amountPaid;
    }
}
