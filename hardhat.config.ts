import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import '@xyrusworx/hardhat-solidity-json';
import { config as dotenvConfig } from 'dotenv';
import 'hardhat-abi-exporter';
import 'hardhat-contract-sizer';
import 'hardhat-deploy';
import 'hardhat-erc1820';
import 'hardhat-gas-reporter';
import 'hardhat-log-remover';
import { HardhatUserConfig } from 'hardhat/config';
import { HardhatNetworkAccountsUserConfig } from 'hardhat/types';
import { resolve } from 'path';
import 'solidity-coverage';
import 'solidity-docgen';
import 'tsconfig-paths/register';

import * as tasks from './tasks';

dotenvConfig({ path: resolve(__dirname, './.env') });
export const mainnetJsonRPCUrl: string = process.env.MAINNET_RPC_URL || 'https://arb1.arbitrum.io/rpc';
export const testnetJsonRPCUrl: string = process.env.TESTNET_RPC_URL || 'https://goerli-rollup.arbitrum.io/rpc';
const explorerApiKey: string | undefined = process.env.ARBISCAN_API_KEY;
if (!explorerApiKey) {
  console.log("ARBISCAN_API_KEY not set in an .env file, deployment verification won't be available");
}

const mainnetAccounts = [process.env.DEPLOYER_PRIVATE_KEY ?? '', process.env.STABILIZER_PRIVATE_KEY || ''];

const MAINNET_USDC_ADDRESS = '0xff970a61a04b1ca14834a43f5de4533ebddb5cc8';
const TESTNET_USDC_ADDRESS = '0x179522635726710dd7d2035a81d856de4aa7836c';

const balance = '100000000000000000000000';
const accounts: HardhatNetworkAccountsUserConfig = [
  {
    privateKey: process.env.DEPLOYER_PRIVATE_KEY || '',
    balance,
  },
  {
    privateKey: process.env.STABILIZER_PRIVATE_KEY || '',
    balance,
  },
];

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  abiExporter: {
    path: './abis',
    clear: true,
    flat: true,
  },
  etherscan: {
    apiKey: explorerApiKey,
  },
  gasReporter: {
    currency: 'USD',
    enabled: !!process.env.REPORT_GAS,
    coinmarketcap: '399a40d3-ac4e-4c92-8f6d-fe901ef01ef0',
    gasPriceApi: 'https://api.etherscan.io/api?module=proxy&action=eth_gasPrice',
    token: 'ETH',
  },
  mocha: {
    timeout: 100000,
  },
  networks: {
    hardhat: {
      chainId: 1337,
      allowUnlimitedContractSize: true,
      gas: 12000000,
      blockGasLimit: 0x1fffffffffffff,
      forking: {
        enabled: true,
        url: mainnetJsonRPCUrl,
      },
      accounts,
    },
    localhost: {
      url: 'http://127.0.0.1:8545',
    },
    staging: {
      url: 'http://127.0.0.1:8545',
      saveDeployments: false,
      companionNetworks: {
        m: 'mainnet',
      },
      accounts: mainnetAccounts,
    },
    testnet: {
      chainId: 421613,
      url: testnetJsonRPCUrl,
      accounts: {
        mnemonic: process.env.LIVENET_MNEMONIC,
        path: "m/44'/60'/0'/0",
        initialIndex: 0,
        count: 2,
      },
    },
    mainnet: {
      chainId: 42161,
      url: mainnetJsonRPCUrl,
      accounts: mainnetAccounts,
    },
  },
  namedAccounts: {
    deployer: 0,
    prevault: 1,
    usdc: {
      42161: MAINNET_USDC_ADDRESS,
      421613: TESTNET_USDC_ADDRESS,
      1337: MAINNET_USDC_ADDRESS,
    },
  },
  solidity: {
    compilers: [
      {
        version: '0.8.17',
        settings: {
          optimizer: {
            enabled: true ?? process.env.OPTIMIZER_DISABLED,
            runs: 250,
          },
          outputSelection: {
            '*': {
              '*': ['storageLayout'],
            },
          },
          evmVersion: 'berlin',
        },
      },
    ],
  },
  typechain: {
    outDir: 'types',
    target: 'ethers-v5',
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: false,
  },
};

tasks;

export default config;
