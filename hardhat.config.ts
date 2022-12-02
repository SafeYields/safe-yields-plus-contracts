import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import {config as dotenvConfig} from 'dotenv';
import 'hardhat-abi-exporter';
import 'hardhat-contract-sizer';
import 'hardhat-deploy';
import 'hardhat-erc1820';
import 'hardhat-gas-reporter';
import 'hardhat-log-remover';
import {HardhatUserConfig} from 'hardhat/config';
import {resolve} from 'path';
import 'solidity-coverage';
import 'solidity-docgen';
import 'tsconfig-paths/register';

import * as tasks from './tasks';
import {HardhatNetworkAccountsUserConfig} from 'hardhat/types';

dotenvConfig({path: resolve(__dirname, './.env')});
export const mainnetJsonRPCUrl: string = process.env.MAINNET_RPC_URL || 'https://bsc-dataseed1.ninicoin.io/';
export const testnetJsonRPCUrl: string = process.env.TESTNET_RPC_URL || 'https://data-seed-prebsc-1-s1.binance.org:8545/';
const explorerApiKey: string | undefined = process.env.BSCSCAN_API_KEY;
if (!explorerApiKey) {
  console.log('BSCSCAN_API_KEY not set in an .env file, dployment verification won\'t be available');
}


const mainnetAccounts = [
  process.env.DEPLOYER_PRIVATE_KEY ?? '',
  process.env.INVESTMENTS_PRIVATE_KEY ?? '',
  process.env.MANAGEMENT_PRIVATE_KEY ?? '',
  process.env.REFERRALS_PRIVATE_KEY ?? '',
];

const balance = '100000000000000000000000';
const accounts: HardhatNetworkAccountsUserConfig = [
  {
    privateKey: process.env.DEPLOYER_PRIVATE_KEY || '',
    balance,
  },
  {
    privateKey: process.env.INVESTMENTS_PRIVATE_KEY || '',
    balance,
  },
  {
    privateKey: process.env.MANAGEMENT_PRIVATE_KEY || '',
    balance,
  },
  {
    privateKey: process.env.REFERRALS_PRIVATE_KEY || '',
    balance,
  }
]

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
    gasPriceApi: 'https://api.bscscan.com/api?module=proxy&action=eth_gasPrice',
    token: 'BNB',
  },
  mocha: {
    timeout: 5000,
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
      chainId: 97,
      url: testnetJsonRPCUrl,
      accounts: {
        mnemonic: process.env.LIVENET_MNEMONIC,
        path: 'm/44\'/60\'/0\'/0',
        initialIndex: 0,
        count: 4,
      },
    },
    mainnet: {
      chainId: 56,
      url: mainnetJsonRPCUrl,
      accounts: mainnetAccounts,
    },
  },
  namedAccounts: {
    deployer: 0,
    investments: 1,
    management: 2,
    referrals: 3,
  },
  solidity: {
    compilers: [
      {
        version: '0.8.17',
        settings: {
          optimizer: {
            enabled: !process.env.OPTIMIZER_DISABLED,
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
