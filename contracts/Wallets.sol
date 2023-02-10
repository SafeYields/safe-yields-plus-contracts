// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract Wallets {
    uint256 constant HUNDRED_PERCENT = 100_000_000;

    /// @dev total wallets on the protocol, see Wallets enum
    uint256 public constant WALLETS = 2;
    // @notice token wallets configuration
    address[WALLETS] public wallets;

    /// @notice protocol wallets for easy enumeration,
    /// @dev the order is extremely important once deployed, see configuration scripts
    // rewards distribution is the balance of SafeNFT,
    enum WalletsUsed {
        Treasury,
        Management
    }

    function _setWallets(address[WALLETS] memory _wallets) internal {
        wallets = _wallets;
    }

    // @notice Distribution percentages, multiplied by 10000, (25 stands for 0.25%)
    function _distribute(IERC20 _paymentToken, uint256 _amount, uint256[WALLETS] storage walletPercentageDistribution) internal returns (uint256) {
        console.log("-- _distribute start --");
        console.log("Distributing %s", _amount);
        console.log("balance %s", _paymentToken.balanceOf(address(this)));
        uint256 amountPaid = 0;
        for (uint256 i = 0; i < WALLETS; i++) {
            uint256 amount = (_amount * walletPercentageDistribution[i]) / HUNDRED_PERCENT;
            console.log("sending %s to %s", amount, wallets[i]);
            _paymentToken.transfer(wallets[i], amount);
            amountPaid += amount;
        }
        console.log("Distributed %s", amountPaid);
        console.log("-- _distribute end --");
        return amountPaid;
    }

    // @notice Distribution percentages, multiplied by 10000, (25 stands for 0.25%)
    function _transferPercent(IERC20 _paymentToken, uint256 _amount, address _receiver, uint256 _percent) internal returns (uint256) {
        console.log("-- _transferPercent start --");
        uint256 balance = _paymentToken.balanceOf(address(this));
        console.log("transferring share of %s", _amount);
        console.log("balance %s", balance);
        uint256 amount = (_amount * _percent) / HUNDRED_PERCENT;
        console.log("amount to transfer %s", amount);
        require(balance >= amount, "Not enough balance on the contract");
        console.log("sending %s to %s", amount, _receiver);
        _paymentToken.transfer(_receiver, amount);
        console.log("Distributed %s", amount);
        console.log("-- _transferPercent end --");
        return amount;
    }

    function _getTotalShare(uint256 _amount, uint256[WALLETS] storage _walletPercentageDistribution, uint256 _extraShare) internal view returns (uint256) {
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < WALLETS; i++) {
            totalPercentage += _walletPercentageDistribution[i];
        }
        totalPercentage += _extraShare;
        return _amount * totalPercentage / HUNDRED_PERCENT;
    }
}
