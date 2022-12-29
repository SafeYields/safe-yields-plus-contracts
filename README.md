# safe-yields-contracts
Safe Yields Smart Contracts
 ____         __       __   ___      _     _
/ ___|  __ _ / _| ___  \ \ / (_) ___| | __| |___
\___ \ / _` | |_ / _ \  \ V /| |/ _ \ |/ _` / __|
___) | (_| |  _|  __/   | | | |  __/ | (_| \__ \
|____/ \__,_|_|  \___|   |_| |_|\___|_|\__,_|___/

# Solidity API

## SafeNFT

Safe Yields NFT token based on ERC1155 standard, id [0..3] represents one of the 4 tiers

### TIERS

```solidity
uint256 TIERS
```

### price

```solidity
uint256[4] price
```

### maxSupply

```solidity
uint256[4] maxSupply
```

### safeToken

```solidity
contract ISafeToken safeToken
```

### safeVault

```solidity
contract ISafeVault safeVault
```

### usd

```solidity
contract IERC20 usd
```

### name

```solidity
string name
```

### priceDistributionOnMint

```solidity
uint256[2] priceDistributionOnMint
```

### profitDistribution

```solidity
uint256[2] profitDistribution
```

### initialize

```solidity
function initialize(string _uri, uint256[4] _price, uint256[4] _maxSupply, contract ISafeToken _safeToken, uint256[2] _priceDistributionOnMint, uint256[2] _profitDistribution) public
```

### constructor

```solidity
constructor(string _uri, uint256[4] _price, uint256[4] _maxSupply, contract ISafeToken _safeToken, uint256[2] _priceDistributionOnMint, uint256[2] _profitDistribution) public
```

### buy

```solidity
function buy(enum ISafeNFT.Tiers _tier, uint256 _amount) public
```

@notice purchase Safe NFT for exact amount of USD
@param _tier tier of the NFT to purchase which stands for ERC1155 token id [0..3]
@param _amount amount of USD to spend

### distributeRewards

```solidity
function distributeRewards(uint256 _amountUSD) public
```

@notice distribute profit among the NFT holders, the function just fixes the amount of the reward currently deposited to the
@param _amountUSD amount of USD to distribute

### claimReward

```solidity
function claimReward() public
```

@notice claims NFT rewards for the caller of the function

### pendingRewards

```solidity
function pendingRewards() external returns (uint256)
```

@notice returns the amount of the reward share for the NFT holder

### percentOfTreasury

```solidity
function percentOfTreasury() external returns (uint256)
```

@notice gets the share of the NFTs of the caller to the treasury

### _afterTokenTransfer

```solidity
function _afterTokenTransfer(address operator, address from, address to, uint256[] ids, uint256[] amounts, bytes data) internal virtual
```

_Hook that is called after any token transfer. This includes minting
and burning, as well as batched variants.

The same hook is called on both single and batched variants. For single
transfers, the length of the `id` and `amount` arrays will be 1.

Calling conditions (for each `id` and `amount` pair):

- When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
  of token type `id` will be  transferred to `to`.
- When `from` is zero, `amount` tokens of token type `id` will be minted
  for `to`.
- when `to` is zero, `amount` of ``from``'s tokens of token type `id`
  will be burned.
- `from` and `to` are never both zero.
- `ids` and `amounts` have the same, non-zero length.

To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks]._

### _beforeTokenTransfer

```solidity
function _beforeTokenTransfer(address operator, address from, address to, uint256[] ids, uint256[] amounts, bytes data) internal virtual
```

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

## SafeToken

This contract is used as a token

### name

```solidity
string name
```

_Returns the name of the token._

### symbol

```solidity
string symbol
```

_Returns the symbol of the token._

### version

```solidity
string version
```

### decimals

```solidity
uint8 decimals
```

_Returns the decimals places of the token._

### totalSupply

```solidity
uint256 totalSupply
```

_Returns the amount of tokens in existence._

### blacklist

```solidity
mapping(address => bool) blacklist
```

### admin

```solidity
mapping(address => uint256) admin
```

### balanceOf

```solidity
mapping(address => uint256) balanceOf
```

_Returns the amount of tokens owned by `account`._

### allowance

```solidity
mapping(address => mapping(address => uint256)) allowance
```

_Returns the remaining number of tokens that `spender` will be
allowed to spend on behalf of `owner` through {transferFrom}. This is
zero by default.

This value changes when {approve} or {transferFrom} are called._

### BUY_TAX_PERCENT

```solidity
uint256 BUY_TAX_PERCENT
```

### SELL_TAX_PERCENT

```solidity
uint256 SELL_TAX_PERCENT
```

### usd

```solidity
contract IERC20 usd
```

@notice Usd token contract used in the protocol (BUSD for now)

### safeVault

```solidity
contract ISafeVault safeVault
```

@notice attached safe vault contract

### taxDistributionOnMintAndBurn

```solidity
uint256[2] taxDistributionOnMintAndBurn
```

### auth

```solidity
modifier auth()
```

### initialize

```solidity
function initialize(address _usdToken, address _safeVault, address[2] _wallets, uint256[2] _taxDistributionOnMintAndBurn) public
```

### constructor

```solidity
constructor(address _usdToken, address _safeVault, address[2] _wallets, uint256[2] _taxDistributionOnMintAndBurn) public
```

### transfer

```solidity
function transfer(address dst, uint256 wad) external returns (bool)
```

### getWallets

```solidity
function getWallets() external view returns (address[2])
```

@notice list of wallets participating in tax distribution on top of the vault

### transferFrom

```solidity
function transferFrom(address src, address dst, uint256 wad) public returns (bool)
```

### mint

```solidity
function mint(address _user, uint256 _amount) external
```

### burn

```solidity
function burn(address _user, uint256 _amount) external
```

### buySafeForExactAmountOfUSD

```solidity
function buySafeForExactAmountOfUSD(uint256 _usdToSpend) public returns (uint256)
```

@notice buy SAFE tokens for given amount of USD, taxes deducted from the provided amount, SAFE is minted
@param _usdToSpend number of tokens to buy, the respective amount of USD will be deducted from the user, Safe Yield token will be minted

### buyExactAmountOfSafe

```solidity
function buyExactAmountOfSafe(uint256 _safeTokensToBuy) public
```

@notice calculate and deduct amount of USD needed to buy given amount of SAFE tokens, SAFE is minted
@param _safeTokensToBuy number of tokens to buy, the respective amount of BUSD will be deducted from the user, Safe Yield token will be minted

### estimateBuyExactAmountOfSafe

```solidity
function estimateBuyExactAmountOfSafe(uint256 _safeTokensToBuy) public
```

### sellExactAmountOfSafe

```solidity
function sellExactAmountOfSafe(uint256 _safeTokensToSell) public
```

@notice sell given amount of SAFE tokens for USD, taxes deducted from the user, SAFE is burned
@param _safeTokensToSell number of tokens to sell, the respective amount of BUSD will be returned from the user, Safe Yield token will be burned

### sellSafeForExactAmountOfUSD

```solidity
function sellSafeForExactAmountOfUSD(uint256 _usdToGet) public
```

@notice calculate the amount of SAFE needed to swap to get the required USD amount an sell it, SAFE is burned
@param _usdToGet number of tokens to buy, the respective amount of BUSD will be deducted from the user, Safe Yield token will be minted

### approve

```solidity
function approve(address usr, uint256 wad) external returns (bool)
```

### rely

```solidity
function rely(address guy) external
```

### deny

```solidity
function deny(address guy) external
```

### getUsdReserves

```solidity
function getUsdReserves() public view returns (uint256)
```

### price

```solidity
function price() public view returns (uint256)
```

@notice price of 1 Safe Yield token in StableCoin

### _mint

```solidity
function _mint(address usr, uint256 wad) internal
```

### _burn

```solidity
function _burn(address usr, uint256 wad) internal
```

### add

```solidity
function add(uint256 x, uint256 y) internal pure returns (uint256 z)
```

### sub

```solidity
function sub(uint256 x, uint256 y) internal pure returns (uint256 z)
```

## SafeVault

This contract is responsible for $BUSD pool: mainly deposit/withdrawal and farms management

### stableCoin

```solidity
contract IERC20 stableCoin
```

### totalSupply

```solidity
uint256 totalSupply
```

### balances

```solidity
mapping(address => uint256) balances
```

### initialize

```solidity
function initialize(address _stableCoin) public
```

### constructor

```solidity
constructor(address _stableCoin) public
```

### deposit

```solidity
function deposit(uint256 _amount) external
```

### withdraw

```solidity
function withdraw(address _receiver, uint256 _amount) external
```

## Wallets

### HUNDRED_PERCENT

```solidity
uint256 HUNDRED_PERCENT
```

### WALLETS

```solidity
uint256 WALLETS
```

_total wallets on the protocol, see Wallets enum_

### wallets

```solidity
address[2] wallets
```

### WalletsUsed

```solidity
enum WalletsUsed {
  InvestmentPool,
  Management
}
```

### _setWallets

```solidity
function _setWallets(address[2] _wallets) internal
```

### _distribute

```solidity
function _distribute(contract IERC20 _paymentToken, uint256 _amount, uint256[2] walletPercentageDistribution) internal returns (uint256)
```

### _getTotalShare

```solidity
function _getTotalShare(uint256 _amount, uint256[2] walletPercentageDistribution) internal view returns (uint256)
```

## ISafeNFT

Safe Yield Vault depositing to the third-party yield farms

### Tiers

```solidity
enum Tiers {
  Tier1,
  Tier2,
  Tier3,
  Tier4
}
```

### buy

```solidity
function buy(enum ISafeNFT.Tiers _tier, uint256 _amount) external
```

@notice purchase Safe NFT for exact amount of USD
@param _tier tier of the NFT to purchase which stands for ERC1155 token id [0..3]
@param _amount amount of USD to spend

### distributeRewards

```solidity
function distributeRewards(uint256 _amountUSD) external
```

@notice distribute profit among the NFT holders, the function just fixes the amount of the reward currently deposited to the
@param _amountUSD amount of USD to distribute

### claimReward

```solidity
function claimReward() external
```

@notice claims NFT rewards for the caller of the function

### pendingRewards

```solidity
function pendingRewards() external returns (uint256)
```

@notice returns the amount of the reward share for the NFT holder

### percentOfTreasury

```solidity
function percentOfTreasury() external returns (uint256)
```

@notice gets the share of the NFTs of the caller to the treasury

## ISafeToken

This contract is used as a token

### buySafeForExactAmountOfUSD

```solidity
function buySafeForExactAmountOfUSD(uint256 _usdToSpend) external returns (uint256)
```

@notice buy SAFE tokens for given amount of USD, taxes deducted from the provided amount, SAFE is minted
@param _usdToSpend number of tokens to buy, the respective amount of USD will be deducted from the user, Safe Yield token will be minted

### buyExactAmountOfSafe

```solidity
function buyExactAmountOfSafe(uint256 _safeTokensToBuy) external
```

@notice calculate and deduct amount of USD needed to buy given amount of SAFE tokens, SAFE is minted
@param _safeTokensToBuy number of tokens to buy, the respective amount of BUSD will be deducted from the user, Safe Yield token will be minted

### sellExactAmountOfSafe

```solidity
function sellExactAmountOfSafe(uint256 _safeTokensToSell) external
```

@notice sell given amount of SAFE tokens for USD, taxes deducted from the user, SAFE is burned
@param _safeTokensToSell number of tokens to sell, the respective amount of BUSD will be returned from the user, Safe Yield token will be burned

### sellSafeForExactAmountOfUSD

```solidity
function sellSafeForExactAmountOfUSD(uint256 _usdToGet) external
```

@notice calculate the amount of SAFE needed to swap to get the required USD amount an sell it, SAFE is burned
@param _usdToGet number of tokens to buy, the respective amount of BUSD will be deducted from the user, Safe Yield token will be minted

### mint

```solidity
function mint(address usr, uint256 wad) external
```

@notice admin function, currently used only to deposit 1 SAFE token to the Safe Vault to set the start price

### burn

```solidity
function burn(address usr, uint256 wad) external
```

@notice admin function

### getWallets

```solidity
function getWallets() external view returns (address[2])
```

@notice list of wallets participating in tax distribution on top of the vault

### usd

```solidity
function usd() external view returns (contract IERC20)
```

@notice Usd token contract used in the protocol (BUSD for now)

### safeVault

```solidity
function safeVault() external view returns (contract ISafeVault)
```

@notice attached safe vault contract

### price

```solidity
function price() external view returns (uint256)
```

@notice price of 1 Safe Yield token in StableCoin

## ISafeVault

Safe Yield Vault depositing to the third-party yield farms

### deposit

```solidity
function deposit(uint256 _amount) external
```

### withdraw

```solidity
function withdraw(address _user, uint256 _amount) external
```

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

