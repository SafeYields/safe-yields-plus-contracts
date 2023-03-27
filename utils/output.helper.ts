import { TierPrices } from '@config';
import { BigNumberish } from '@ethersproject/bignumber';
import chalk from 'chalk';
import { BigNumber, ethers } from 'ethers';
import { DeployResult } from 'hardhat-deploy/dist/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

const suppresableLogger = (hide: boolean | string | undefined, logger: (message: any) => void) => (message: any) =>
  !hide && logger(message);

const taskLogger = suppresableLogger(process.env.HIDE_TASK_LOG, console.log);
export const info = (message: string) => taskLogger(chalk.dim(message));
export const announce = (message: string) => taskLogger(chalk.cyan(message));
export const table = (message: any) => suppresableLogger(process.env.HIDE_TASK_LOG, console.table)(message);
export const success = (message: string) => taskLogger(chalk.green(message));
export const warning = (message: string) => taskLogger(chalk.yellow(message));
export const error = (message: string) => taskLogger(chalk.red(message));

const deployLogger = suppresableLogger(process.env.HIDE_DEPLOY_LOG, console.log);
export const deployInfo = (message: string) => deployLogger(chalk.dim(message));
export const deployError = (message: string) => deployLogger(chalk.red(message));
export const deployAnnounce = (message: string) => deployLogger(chalk.cyan(message));
export const deployWarning = (message: string) => deployLogger(chalk.yellow(message));
export const deploySuccess = (message: string) => deployLogger(chalk.green(message));

export const networkInfo = async (hre: HardhatRuntimeEnvironment, display: (message: string) => void) =>
  !process.env.HIDE_SHOW_NETWORK &&
  display(`Network:  (${hre.network.live ? `${chalk.red('live!')}, ${hre.network.name}` : chalk.yellow('local')})\n`);

export const displayDeployResult = (name: string, result: DeployResult) =>
  !result.newlyDeployed
    ? deployWarning(`Re-used existing ${name} at ${result.address}`)
    : deploySuccess(`${name} deployed at ${result.address}`);

export const toBigNumber = (value: number | string | BigNumber, decimals = 6) =>
  ethers.utils.parseUnits(value.toString(), decimals);
export const fromBigNumber = (value: BigNumberish, decimals = 6) => ethers.utils.formatUnits(value, decimals);
export const fromBigNumberToFloat = (value: BigNumberish, decimals = 6) =>
  parseFloat(ethers.utils.formatUnits(value, decimals));
export const formattedFromBigNumber = (value: BigNumberish, decimals = 6) =>
  Number(Number(fromBigNumber(value, decimals)).toFixed(5));

export const sayMaximumForMaxUint = (allowance: BigNumber) =>
  allowance.eq(ethers.constants.MaxUint256) ? chalk.magenta('Maximum') : fromBigNumber(allowance);
export const displayDiscountedPresalePriceNFT = (tierPrices: TierPrices[], displayFunc: (message: string) => void) =>
  tierPrices.map((tierPrices, week) =>
    displayFunc(`Week: ${week} ${Object.values(tierPrices).map(v => fromBigNumber(v).padStart(8, ' '))}`),
  );
