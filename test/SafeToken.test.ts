import { fromPercent, safeTokenTax } from '@config';
import { SafeToken, SafeVault } from '@contractTypes/contracts';
import { fromBigNumberToFloat, toBigNumber } from '@utils/output.helper';
import erc20abi from 'abi/erc20abi.json';
import { expect } from 'chai';
import newDebug from 'debug';
import { Contract } from 'ethers';
import hardhat, { deployments, ethers } from 'hardhat';
import { Address } from 'hardhat-deploy/dist/types';

const debug = newDebug('safe:SafeToken.test.ts');
describe('SafeToken', () => {
  let safeTokenContract: SafeToken;
  let safeTokenContractOtherUser: SafeToken;
  let safeVaultContract: SafeVault;
  let safeVaultContractOtherUser: SafeVault;
  let usdContract: Contract;
  let usdContractOtherUser: Contract;
  let namedAccounts: { [name: string]: Address };
  let user: Address;
  let otherUsers: Address[];
  let otherUser: Address;
  // test running parameters
  const testAmountBN = 10 * 1e6;
  const roundingPrecisonError = 0.00001;
  const numberOfFuzzingTests = 30;
  const fuzzingTestAmount = 80_000 / numberOfFuzzingTests;

  const notGreaterThanUsdBalance = async (amount: number, address: Address = otherUser) =>
    toBigNumber(Math.min(amount, fromBigNumberToFloat(await usdContract.balanceOf(address))));

  beforeEach(async () => {
    await deployments.fixture(['SafeVault', 'SafeToken', 'SafeNFT', 'Config']);
    safeVaultContract = await ethers.getContract<SafeVault>('SafeVault');
    safeTokenContract = await ethers.getContract<SafeToken>('SafeToken');
    namedAccounts = await hardhat.getNamedAccounts();
    usdContract = await ethers.getContractAt(erc20abi, namedAccounts.usdc);
    user = namedAccounts.deployer;
    otherUsers = await hardhat.getUnnamedAccounts();
    otherUser = otherUsers[0];
    usdContractOtherUser = await ethers.getContractAt(erc20abi, namedAccounts.usdc, otherUser);
    safeVaultContractOtherUser = await ethers.getContract<SafeVault>('SafeVault', otherUser);
    safeTokenContractOtherUser = await ethers.getContract<SafeToken>('SafeToken', otherUser);
  });

  describe('mint(address _user, uint256 _amount)', () => {
    it('owner should be able to mint safe token to himself', async () => {
      await expect(safeTokenContract.mint(user, testAmountBN))
        .to.emit(safeTokenContract, 'Transfer')
        .withArgs(ethers.constants.AddressZero, user, testAmountBN);
      expect(await safeTokenContract.balanceOf(user)).to.equal(testAmountBN);
    });

    it('owner should be able to mint safe token to anybody', async () => {
      await expect(safeTokenContract.mint(otherUser, testAmountBN))
        .to.emit(safeTokenContract, 'Transfer')
        .withArgs(ethers.constants.AddressZero, otherUser, testAmountBN);
      expect(await safeTokenContract.balanceOf(otherUser)).to.equal(testAmountBN);
    });

    it('non-owner should not be able to mint safe token', async () => {
      await expect(safeTokenContractOtherUser.mint(otherUser, testAmountBN)).to.be.revertedWith(
        'SafeToken:not-authorized',
      );
    });
  });

  describe('transfer(address dst, uint256 amt)', () => {
    it('owner should be able to transfer tokens to himself', async () => {
      await safeTokenContract.mint(user, testAmountBN);
      await expect(safeTokenContract.transfer(user, testAmountBN))
        .to.emit(safeTokenContract, 'Transfer')
        .withArgs(user, user, testAmountBN);
      expect(await safeTokenContract.balanceOf(user)).to.equal(testAmountBN);
    });

    it('owner should be able to transfer personal tokens to anybody', async () => {
      await safeTokenContract.mint(user, testAmountBN);
      await expect(safeTokenContract.transfer(otherUser, testAmountBN))
        .to.emit(safeTokenContract, 'Transfer')
        .withArgs(user, otherUser, testAmountBN);
      expect(await safeTokenContract.balanceOf(otherUser)).to.equal(testAmountBN);
      expect(await safeTokenContract.balanceOf(user)).to.be.equal(0);
    });

    it('non-owner user should not be able to transfer tokens', async () => {
      await safeTokenContract.mint(otherUser, testAmountBN);
      await expect(safeTokenContractOtherUser.transfer(otherUser, testAmountBN)).to.be.revertedWith(
        'SafeToken: transfer-prohibited',
      );
    });

    it('non-owner user should be able to transfer tokens if whitelisted', async () => {
      await safeTokenContract.mint(otherUser, testAmountBN);
      await safeTokenContract.whitelistAdd(otherUser);
      await expect(safeTokenContractOtherUser.transfer(user, testAmountBN))
        .to.emit(safeTokenContract, 'Transfer')
        .withArgs(otherUser, user, testAmountBN);
      expect(await safeTokenContract.balanceOf(otherUser)).to.equal(0);
      expect(await safeTokenContract.balanceOf(user)).to.be.equal(testAmountBN);
    });

    it('non-owner user should not be able to transfer tokens if removed from whitelist', async () => {
      await safeTokenContract.mint(otherUser, testAmountBN);
      await safeTokenContract.whitelistAdd(otherUser);
      await safeTokenContract.whiteListRemove(otherUser);
      await expect(safeTokenContractOtherUser.transfer(otherUser, testAmountBN)).to.be.revertedWith(
        'SafeToken: transfer-prohibited',
      );
    });
  });

  describe('transferFrom(address src, address dst, uint256 amt)', () => {
    it("owner should be able to transfer someone's tokens to anybodey", async () => {
      await safeTokenContract.mint(otherUser, testAmountBN * 1.5);
      await expect(safeTokenContract.transferFrom(otherUser, user, testAmountBN))
        .to.emit(safeTokenContract, 'Transfer')
        .withArgs(otherUser, user, testAmountBN);
      expect(await safeTokenContract.balanceOf(otherUser)).to.equal(testAmountBN * 0.5);
      expect(await safeTokenContract.balanceOf(user)).to.equal(testAmountBN);
    });
  });

  describe('name', () => {
    it('Should return the contract name created in constructor', async () => {
      expect(await safeTokenContract.name()).to.equal('Safe Yields Token');
    });
  });

  describe('symbol', () => {
    it('Should return the contract symbol created in constructor', async () => {
      expect(await safeTokenContract.symbol()).to.equal('SAFE');
    });
  });

  describe('balanceOf', () => {
    it('Should return the address balance', async () => {
      await safeTokenContract.mint(user, testAmountBN);
      expect(await safeTokenContract.balanceOf(user)).to.equal(testAmountBN);
    });
  });

  describe('totalSupply', () => {
    it('Should return the contract totalSupply', async () => {
      await safeTokenContract.mint(user, testAmountBN);
      await safeTokenContract.mint(otherUser, testAmountBN);
      expect(await safeTokenContract.totalSupply()).to.equal(testAmountBN * 2);
    });
  });

  describe('Decimals', () => {
    it("Should return the dechimals once it's changed", async () => {
      expect(await safeTokenContract.decimals()).to.equal(6);
    });
  });

  describe('Burn token', () => {
    it('Burn token for address', async () => {
      await safeTokenContract.mint(otherUser, testAmountBN * 35);
      await safeTokenContract.burn(otherUser, testAmountBN * 12);
      expect(await safeTokenContract.balanceOf(otherUser)).to.equal(testAmountBN * 23);
    });
  });

  describe('Allowance token with approve', () => {
    it('Allowance token for address', async () => {
      await safeTokenContract.mint(user, testAmountBN * 100);
      await safeTokenContract.approve(otherUser, testAmountBN * 20);
      expect(await safeTokenContract.allowance(user, otherUser)).to.equal(testAmountBN * 20);
    });
  });

  describe('Pause', () => {
    it('should get the pause info', async () => {
      expect(await safeTokenContract.paused()).to.equal(false);
    });
    it('owner should be able to pause', async () => {
      await safeTokenContract.pause();
      expect(await safeTokenContract.paused()).to.equal(true);
    });
    it('paused contract mints to the owner', async () => {
      await safeTokenContract.pause();
      await expect(safeTokenContract.mint(user, testAmountBN))
        .to.emit(safeTokenContract, 'Transfer')
        .withArgs(ethers.constants.AddressZero, user, testAmountBN);
    });

    it("paused contract doesn't transfer", async () => {
      await safeTokenContract.pause();
      await safeTokenContract.mint(otherUser, testAmountBN);
      await expect(safeTokenContractOtherUser.transfer(otherUser, testAmountBN)).to.be.revertedWith('SafeToken:paused');
    });

    it('non-owner should not be able to pause', async () => {
      await expect(safeTokenContractOtherUser.pause()).to.be.revertedWith('SafeToken:not-authorized');
    });
  });

  describe('Price and token mechanics', async () => {
    const checkPrice = async (priceBeforeOperation: number) => {
      const vaultBalance = fromBigNumberToFloat(await usdContract.balanceOf(safeVaultContract.address));
      debug('Vault balance', vaultBalance);
      const safeTokenSupply = fromBigNumberToFloat(await safeTokenContract.totalSupply());
      debug('Safe token supply', safeTokenSupply);
      const pricePostPurchase = fromBigNumberToFloat(await safeTokenContract.price());
      debug('Price post operation', pricePostPurchase);
      // such a precision is fine for now
      expect(pricePostPurchase).to.be.gte(parseFloat((vaultBalance / safeTokenSupply).toFixed(6)) - 0.00001);
      expect(pricePostPurchase).to.be.lte(parseFloat((vaultBalance / safeTokenSupply).toFixed(6)) + 0.00001);
      expect(pricePostPurchase).to.be.gte(priceBeforeOperation);
      expect(pricePostPurchase).to.be.gte(1);
    };

    beforeEach(async () => {
      // await deployments.fixture(['SafeVault', 'SafeToken', 'SafeNFT', 'Config']);
      await hardhat.run('fund');
      await hardhat.run('fund', { user: otherUser });
      await hardhat.run('init');
      await hardhat.run('permit');
      await hardhat.run('permit', { user: otherUser });
    });

    it('should get the price', async () => {
      expect(await safeTokenContract.price()).to.equal(1e6);
    });

    it(`buySafeForExactAmountOfUSD(uint256 _usdToSpend) user can get Safe for a given amount of USDC tokens  and safe price correctly increases`, async () => {
      for (const amountUsdToSpend of Array.from({ length: numberOfFuzzingTests }, () =>
        Math.floor(Math.random() * 3000 + 1),
      )) {
        // amount to spend, say 10 usd
        debug('Amount of USD to buy SAFE for', amountUsdToSpend);
        const initialSafeSupply = fromBigNumberToFloat(await safeTokenContract.totalSupply());
        const initialUsdBalance = fromBigNumberToFloat(await usdContract.balanceOf(otherUser));
        // safe price (say 1 USD)
        const price = fromBigNumberToFloat(await safeTokenContract.price());
        debug('Price', price);
        const initialSafeBalance = fromBigNumberToFloat(await safeTokenContract.balanceOf(otherUser));
        //////////////////////
        await safeTokenContractOtherUser.buySafeForExactAmountOfUSD(toBigNumber(amountUsdToSpend));
        //////////////////////
        // tax in USD, so if 10, then tax is 0.25% x 10 = 0.025 USD
        const tax = amountUsdToSpend * fromPercent(safeTokenTax.buyTaxPercent);
        debug('Tax', tax);
        // safe to get is (10 - 0.025) / price = 9.975
        const safeTokensToGet = (amountUsdToSpend - tax) / price;
        debug('safeTokens', safeTokensToGet);
        const safeBalanceChanged = safeTokensToGet + initialSafeBalance;
        const safeBalance = fromBigNumberToFloat(await safeTokenContract.balanceOf(otherUser));
        expect(safeBalance).to.be.gte(safeBalanceChanged - 0.00001);
        expect(safeBalance).to.be.lte(safeBalanceChanged + 0.00001);

        const usdBalancePostPurchase = initialUsdBalance - amountUsdToSpend;
        debug('USD balance post purchase', usdBalancePostPurchase);
        expect(fromBigNumberToFloat(await usdContract.balanceOf(otherUser)) - usdBalancePostPurchase).to.be.lte(
          roundingPrecisonError,
        );
        expect(
          fromBigNumberToFloat(await safeTokenContract.totalSupply()) - (initialSafeSupply + safeTokensToGet),
        ).to.be.lte(roundingPrecisonError);
        expect(safeBalance - safeBalanceChanged).to.be.lte(roundingPrecisonError);
        await checkPrice(price);
      }
    });

    it(`buyExactAmountOfSafe(uint256 _safeTokensToBuy) user can get exactly number of safe tokens and safe price correctly increases`, async () => {
      // that's not a deterministic test, but it's ok since shows the output in debug log
      for (const amountOfSafeToBuy of Array.from({ length: numberOfFuzzingTests }, () =>
        Math.floor(Math.random() * 3000 + 1),
      )) {
        // test amount to use, 10 tokens
        debug('--------------------------------------', amountOfSafeToBuy);
        debug('Amount of Safe to buy for the test', amountOfSafeToBuy);
        // we keep all amounts for test in float human-readable numbers
        const price = fromBigNumberToFloat(await safeTokenContract.price());
        debug('Current Safe Token price', price);
        const amountInUSD = price * amountOfSafeToBuy;
        debug('amountInUSD of the purchase', amountInUSD);
        // tax is 0.25%
        const tax = amountInUSD * fromPercent(safeTokenTax.buyTaxPercent);
        debug('tax', tax.toString());
        const amountUsdUserSpends = amountInUSD + tax;
        debug('amountUsdUserSpends', amountUsdUserSpends);
        const initialSupply = fromBigNumberToFloat(await safeTokenContract.totalSupply());
        debug('initialSupply of SafeToken', initialSupply);
        const initialUsdBalance = fromBigNumberToFloat(await usdContractOtherUser.balanceOf(otherUser));
        const initialSafeBalance = fromBigNumberToFloat(await safeTokenContract.balanceOf(otherUser));
        //////////////////////
        await safeTokenContractOtherUser.buyExactAmountOfSafe(toBigNumber(amountOfSafeToBuy));
        //////////////////////
        const usdBalancePostPurchase = initialUsdBalance - amountUsdUserSpends;
        debug('user change in usd balance', usdBalancePostPurchase);
        expect(fromBigNumberToFloat(await safeTokenContract.balanceOf(otherUser))).to.equal(
          initialSafeBalance + amountOfSafeToBuy,
        );
        expect(
          fromBigNumberToFloat(await usdContractOtherUser.balanceOf(otherUser)) - usdBalancePostPurchase,
        ).to.be.lte(roundingPrecisonError);
        expect(fromBigNumberToFloat(await safeTokenContract.totalSupply())).to.equal(initialSupply + amountOfSafeToBuy);
        await checkPrice(price);
      }
    });

    describe('fuzzing sellExactAmountOfSafe(uint256 _safeToSell)', async () => {
      // that's not a deterministic test, but it's ok since shows the output in debug log
      Array.from({ length: numberOfFuzzingTests }, () => Math.floor(Math.random() * fuzzingTestAmount + 1)).forEach(
        amountOfSafeToSell => {
          it(`user can sell ${amountOfSafeToSell} safe tokens and safe price correctly increases`, async () => {
            // test amount to use, 10 tokens
            debug('>> Amount of Safe to sell for the test', amountOfSafeToSell);
            await safeTokenContractOtherUser.buyExactAmountOfSafe(toBigNumber(amountOfSafeToSell));
            // we keep all amounts for test in float human-readable numbers
            const price = fromBigNumberToFloat(await safeTokenContract.price());
            debug('Current Safe Token price', price);
            const amountInUSDBeforeTax = amountOfSafeToSell * price;
            debug('amountInUSDBeforeTax', amountInUSDBeforeTax);
            // tax is 0.25%
            const tax = amountInUSDBeforeTax * fromPercent(safeTokenTax.sellTaxPercent);
            debug('tax', tax.toString());
            const amountUsdToReturnToUser = amountInUSDBeforeTax - tax;
            debug('amountUsdToReturnToUser', amountUsdToReturnToUser);
            const initialSupply = fromBigNumberToFloat(await safeTokenContract.totalSupply());
            debug('initialSupply of SafeToken', initialSupply);
            const initialUsdBalance = fromBigNumberToFloat(await usdContractOtherUser.balanceOf(otherUser));
            const initialSafeBalance = fromBigNumberToFloat(await safeTokenContract.balanceOf(otherUser));
            //////////////////////
            await safeTokenContractOtherUser.sellExactAmountOfSafe(toBigNumber(amountOfSafeToSell));
            //////////////////////
            const usdBalancePostSell = initialUsdBalance + amountUsdToReturnToUser;
            debug('user change in usd balance', usdBalancePostSell);
            expect(fromBigNumberToFloat(await safeTokenContract.balanceOf(otherUser))).to.equal(
              initialSafeBalance - amountOfSafeToSell,
            );
            const usdBalance = fromBigNumberToFloat(await usdContractOtherUser.balanceOf(otherUser));
            expect(usdBalance).to.be.gte(usdBalancePostSell - 0.00001);
            expect(usdBalance).to.be.lte(usdBalancePostSell + 0.00001);
            expect(fromBigNumberToFloat(await safeTokenContract.totalSupply())).to.equal(
              initialSupply - amountOfSafeToSell,
            );
            await checkPrice(price);
          });
        },
      );
    });

    describe('fuzzing sellSafeForExactAmountOfUSD(uint256 _safeToSell)', async () => {
      // that's not a deterministic test, but it's ok since shows the output in debug log
      Array.from({ length: numberOfFuzzingTests }, () => Math.floor(Math.random() * fuzzingTestAmount + 1)).forEach(
        amountOfUsdToReturnToUser => {
          it(`user can get ${amountOfUsdToReturnToUser} for an amount of safe tokens and safe price correctly increases`, async () => {
            // test amount to use, 10 tokens
            await safeTokenContractOtherUser.buyExactAmountOfSafe(
              toBigNumber(amountOfUsdToReturnToUser * fromBigNumberToFloat(await safeTokenContract.price()) * 2),
            );
            const price = fromBigNumberToFloat(await safeTokenContract.price());
            debug('>> Amount of USD to get for the test', amountOfUsdToReturnToUser);
            // we keep all amounts for test in float human-readable numbers
            debug('Current Safe Token price', price);
            const tax = amountOfUsdToReturnToUser * fromPercent(safeTokenTax.sellTaxPercent);
            const amountOfSafeToBurn = (amountOfUsdToReturnToUser + tax) / price;
            debug('amountOfSafeToBurn', amountOfSafeToBurn);
            // tax is 0.25%
            debug('tax', tax);
            const initialSupply = fromBigNumberToFloat(await safeTokenContract.totalSupply());
            const initialUsdBalance = fromBigNumberToFloat(await usdContract.balanceOf(otherUser));
            const initialSafeBalance = fromBigNumberToFloat(await safeTokenContract.balanceOf(otherUser));
            //////////////////////
            await safeTokenContractOtherUser.sellSafeForExactAmountOfUSD(toBigNumber(amountOfUsdToReturnToUser));
            //////////////////////
            const usdBalancePostSellEtalon = initialUsdBalance + amountOfUsdToReturnToUser;
            const safeBalancePostSellEtalon = initialSafeBalance - amountOfSafeToBurn;
            debug('user change in usd balance', usdBalancePostSellEtalon);
            const safeBalancePostSellQueriedFromContract = fromBigNumberToFloat(
              await safeTokenContract.balanceOf(otherUser),
            );
            expect(safeBalancePostSellQueriedFromContract - safeBalancePostSellEtalon).to.be.lte(roundingPrecisonError);
            const usdBalancePostSellQueriedFromContract = fromBigNumberToFloat(await usdContract.balanceOf(otherUser));
            expect(usdBalancePostSellQueriedFromContract - usdBalancePostSellEtalon).to.be.lte(roundingPrecisonError);
            expect(
              fromBigNumberToFloat(await safeTokenContract.totalSupply()) - (initialSupply - amountOfSafeToBurn),
            ).to.be.lte(roundingPrecisonError);
            await checkPrice(price);
          });
        },
      );
    });

    it('consequent buy and sell fuzzing test', async () => {
      // that's not a deterministic test, but it's ok since shows the output in debug log
      for (const amount of Array.from({ length: numberOfFuzzingTests }, () =>
        Math.floor(Math.random() * fuzzingTestAmount + 1),
      )) {
        debug('--------------------------------------');
        debug(`buying ${amount} safe tokens`);
        let price = fromBigNumberToFloat(await safeTokenContract.price());
        await safeTokenContractOtherUser.buyExactAmountOfSafe(toBigNumber(amount));
        await checkPrice(price);
        const amountToSell = Math.floor(
          Math.random() * fromBigNumberToFloat(await safeTokenContract.balanceOf(otherUser)) + 1,
        );
        price = fromBigNumberToFloat(await safeTokenContract.price());
        debug(`selling ${amountToSell} safe tokens`);
        await safeTokenContractOtherUser.sellExactAmountOfSafe(toBigNumber(amountToSell));
        await checkPrice(price);
      }
    });

    it('consequent buy and sell fuzzing test with vault deposit', async () => {
      // that's not a deterministic test, but it's ok since shows the output in debug log
      const depositToVault = async () => {
        const amountToDepositToVault = Math.floor(
          (Math.random() * fromBigNumberToFloat(await usdContract.balanceOf(otherUser))) / 2,
        );
        if (amountToDepositToVault > 0) {
          debug(`depositing ${amountToDepositToVault} stable coin tokens to vault`);
          const price = fromBigNumberToFloat(await safeTokenContract.price());
          await safeVaultContractOtherUser.deposit(toBigNumber(amountToDepositToVault));
          await checkPrice(price);
        }
      };

      for (const amount of Array.from(
        { length: numberOfFuzzingTests },
        () => Math.floor(Math.random() * fuzzingTestAmount) + 1,
      )) {
        debug('--------------------------------------');
        debug(`buying ${amount} safe tokens`);
        let price = fromBigNumberToFloat(await safeTokenContract.price());
        const amountToUse = await notGreaterThanUsdBalance(amount);
        if (amountToUse.gt(0)) {
          await safeTokenContractOtherUser.buySafeForExactAmountOfUSD(notGreaterThanUsdBalance(amount));
          await checkPrice(price);
          await depositToVault();
          price = fromBigNumberToFloat(await safeTokenContract.price());
          const amountToSell = Math.floor(
            Math.random() * (fromBigNumberToFloat(await safeTokenContract.balanceOf(otherUser)) - 1) + 1,
          );
          if (amountToSell > 0) {
            debug(`selling ${amountToSell} safe tokens`);
            await safeTokenContractOtherUser.sellExactAmountOfSafe(toBigNumber(amountToSell));
            await checkPrice(price);
            await depositToVault();
          }
        }
      }
    });
  });
});
