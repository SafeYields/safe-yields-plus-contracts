import { WEEK, discountedPresalePriceNFT, presaleMaxSupply } from '@config';
import { SafeNFT } from '@contractTypes/contracts';
import { displayDiscountedPresalePriceNFT, info, networkInfo, success } from '@utils/output.helper';
import { task, types } from 'hardhat/config';
import moment from 'moment';

const timeStampFormat = 'DD.MM.YYYY HH:mm:ss?';
export default task('presale', 'gets and sets presale date to now or other date')
  .addOptionalParam(
    'test',
    'update the date (default is false which only reads and displays the date)',
    true,
    types.boolean,
  )
  .addOptionalParam('price', 'update the discounted price table and maxSupply per week', false, types.boolean)
  .addOptionalParam('setdate', 'update the startDate', false, types.boolean)
  .addOptionalParam(
    'date',
    `presale date to set in format ${timeStampFormat}`,
    moment().format(timeStampFormat),
    types.string,
  )
  .setAction(async ({ test, price, setdate, date }, hre) => {
    await networkInfo(hre, info);

    const nftContract = await hre.ethers.getContract<SafeNFT>('SafeNFT');
    info(
      `current presale start date is: ${moment
        .unix((await nftContract.presaleStartDate()).toNumber())
        .format(timeStampFormat)}`,
    );
    if (!test) {
      if (setdate) {
        const timeStamp = moment(date, timeStampFormat).unix();
        info(`setting presale start to ${date}, which is ${timeStamp}`);
        await (await nftContract.setPresaleStartDate(timeStamp, WEEK(hre.network.name))).wait();
      }
      if (price) {
        info(`setting discounted price table start to:`);
        displayDiscountedPresalePriceNFT(discountedPresalePriceNFT, info);
        await (await nftContract.setDiscountedPriceTable(discountedPresalePriceNFT.map(o => Object.values(o)))).wait();
        info(`setting presaleMaxSupply to: ${presaleMaxSupply}`);
        await (await nftContract.setPresaleMaxSupply(presaleMaxSupply)).wait();
      } else {
        info('skipping price table update since price parameter is not set to true');
      }

      success('Done.');
    }
  });
