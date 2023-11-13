// SPDX-License-Identifier: No License
pragma solidity 0.8.20;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

contract ArbBot {

    ISwapRouter public swapRouter;
    IUniswapV3Factory  public factory;
    address public token0;
    address public token1;
    uint24 public feeTier1;
    uint24 public feeTier2;

    constructor(ISwapRouter _swapRouter, IUniswapV3Factory _factory, address _token0, address _token1, uint24 _feeTier1, uint24 _feeTier2) {
        swapRouter = _swapRouter;
        token0 = _token0;
        token1 = _token1;
        // feeTier1 must be the smaller fee
        feeTier1 = _feeTier1;
        feeTier2 = _feeTier2;
        factory = _factory;
    }

   
    function _swapToken0forToken1(uint256 token0In) private returns (uint256 amountOut) {

        require(IERC20(token0).allowance(msg.sender, address(this))>token0In, "Not sufiicient funds approved");
        TransferHelper.safeTransferFrom(token0, msg.sender, address(this), token0In);

        TransferHelper.safeApprove(token0, address(swapRouter), token0In);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token0,
                tokenOut: token1,
                fee: feeTier1,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: token0In,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    function _swapToken1forToken0(uint256 amountIn) private returns (uint256 amountOut) {
        require(IERC20(token1).allowance(msg.sender, address(this))>amountIn, "Not sufiicient funds approved");
        TransferHelper.safeTransferFrom(token1, msg.sender, address(this), amountIn);

        TransferHelper.safeApprove(token0, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token1,
                tokenOut: token0,
                fee: feeTier2,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    function executeArbitrage(uint256 token0In) external returns(uint256) {
        require(checkForArbitrage(), "No arbitrage opportunities");
        uint256 token1Out = _swapToken0forToken1(token0In);
        uint256 token0Out = _swapToken1forToken0(token1Out);
        return token0Out - token0In;
    }

    // The logic behind the formula is that per each swap a fraction proportional to the fee of the pool get removed each time,
    // So there will be a profit if after removing fee charges, the amount of token received at the end will be more then 
    // initially swapped amount. 
    function checkForArbitrage() public view returns(bool) {
        uint256 pricePool1 = getPrice(feeTier1);
        uint256 pricePool2 = getPrice(feeTier2);
        uint256 fee1 = uint256(feeTier1/1000000);
        uint256 fee2 = uint256(feeTier2/1000000);
        if(pricePool2>pricePool1*((1-fee1)*(1-fee2))){
            return true;
        } else {
            return false;
        }
        
    }

     function getPrice(uint24 fee) public view returns (uint256 price)
    {
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(token0, token1, fee));
        (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
        return uint(sqrtPriceX96) * uint(sqrtPriceX96) * (1e18) >> (96 * 2);
    }
    

}