import chalk from 'chalk';
import { DeployResult } from 'hardhat-deploy/dist/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

type MutableObject<T> = { -readonly [P in keyof T]: T[P] };

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
  display(`Network:  (${hre.network.live ? chalk.red('live!') : chalk.yellow('local')})\n`);

export const displayDeployResult = (name: string, result: DeployResult) =>
  !result.newlyDeployed
    ? deployWarning(`Re-used existing ${name} at ${result.address}`)
    : deploySuccess(`${name} deployed at ${result.address}`);
