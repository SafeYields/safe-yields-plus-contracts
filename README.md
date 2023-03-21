# safe-yields-contracts
Safe Yields Smart Contracts
```
 ____         __       __   ___      _     _
/ ___|  __ _ / _| ___  \ \ / (_) ___| | __| |___
\___ \ / _` | |_ / _ \  \ V /| |/ _ \ |/ _` / __|
___) | (_| |  _|  __/   | | | |  __/ | (_| \__ \
|____/ \__,_|_|  \___|   |_| |_|\___|_|\__,_|___/
```

[![Compile & Test Pass](https://github.com/Safe-Yields/safe-yields-contracts/actions/workflows/test.yml/badge.svg)](https://github.com/Safe-Yields/safe-yields-contracts/actions/workflows/test.yml)

## Overview

Safe Yields is a DeFi protocol on Arbitrum blockchain implementing a deflationary token mathematically
designed to sustain positive price action.
More details are available on https://www.safeyields.io/.

- [Whitepaper](https://www.safeyields.io/safeyields_whitepaper.pdf)
- [Litepaper](https://www.safeyields.io/safeyields_litepaper.pdf)

## Preparation

Copy `.env.example` to `.env`.

```shell
$ yarn install
```

## Testing

To run unit & integration tests:

```shell
$ yarn test
```

To run the coverage:

```shell
$ yarn coverage
```

Note to compile the contracts and build the types with `yarn typechain` prior to that if you're running
coverage as the
first command after installation.

## Local development node, Arbitrum Mainnet fork

```shell
yarn start
```

## Deployment

Deployment (or upgrading) the contracts are done with

```shell
yarn deploy NETWORK   #NETWORK is localhost, testnet or mainnet
```

Scripts in [/deploy](./deploy) as well as the handy scripts below work with any network managed by the hardhat and
hardhat-deploy.

## Contracts

The contracts are upgradable both ERC-173 and ERC-1967 transparent proxy compliant.

### Overview

- [SafeNFT.sol](contracts%2FSafeNFT.sol) : ERC-1155 compatible NFT implementing Safe NFT, including presale tokens.
- [SafeToken.sol](contracts%2FSafeToken.sol) : ERC-20 compatible token.
- [SafeVault.sol](contracts%2FSafeVault.sol) : A vault that manages stable coins deposited to the project which may
  deposit
  funds to yield farms and withdraws as a part of withdrawal tx.

### Addresses

#### Arbitrum Mainnet

|   Contract  | Address    |
|-----|-----|
|   SafeNFT  |     [0xe2967C90F8cec65Ae12c4bC36c771249C12a2310](https://arbiscan.io/address/0xe2967C90F8cec65Ae12c4bC36c771249C12a2310) |
|   SafeToken  |  [0x519EfB2bEFBd3f00D335dc9DF42BF721D591604f](https://arbiscan.io/address/0x519EfB2bEFBd3f00D335dc9DF42BF721D591604f)    |


#### Arbitrum Testnet

|   Contract  | Address                                                                                                                   |
|-----|---------------------------------------------------------------------------------------------------------------------------|
|   SafeNFT  | [0xAa1D2ca80198470dbCC594CbcA8B7Ea4cBf9a3fE](https://test.arbiscan.io/address/0xAa1D2ca80198470dbCC594CbcA8B7Ea4cBf9a3fE) |
|   SafeToken  | [0xeeC181F2008b0f719e572000b1F02F120634326C](https://test.arbiscan.io/address/0xeeC181F2008b0f719e572000b1F02F120634326C) |



## NFT Presale

NFT presale Starts 3rd of March 2023, 17:00 UTC and ends on 31 March 2023, 17:00 UTC decreasing in price every week.

