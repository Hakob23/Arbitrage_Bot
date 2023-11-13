

const { computePoolAddress, FeeAmount } = require('@uniswap/v3-sdk')
const { Token } = require('@uniswap/sdk-core')
const IUniswapV3PoolABI = require('@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json')
const { Pool } = require('@uniswap/v3-sdk')

async function main() {
    const [deployer] = await ethers.getSigners();

    const TOKEN0_ADDRESS = "0x07Af94D5bD598Ae45E162eb2D0A5F7bb71C3F77C"
    const TOKEN1_ADDRESS = "0x775C93773d366D4aA3c2Ad760D1206C89F680e94"
    const POOL_ADDRESS = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88"

    const FACTORY_ADDRESS = "0x1F98431c8aD98523631AE4a59f267346ea31F984"
    const ROUTER_ADDRESS = "0xE592427A0AEce92De3Edee1F18E0157C05861564"

    const FEE_TIER1 = 500 // 0.05
    const FEE_TIER2 = 3000 // 0.3
    const FEE_TIER3 = 10000 // 1

    const arbContract = await ethers.deployContract("ArbBot",  [ROUTER_ADDRESS, FACTORY_ADDRESS, TOKEN0_ADDRESS, TOKEN1_ADDRESS, FEE_TIER1, FEE_TIER2])
    
    console.log(await arbContract.checkForArbitrage());
    console.log(await arbContract.getAddress());
    
}
  

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});