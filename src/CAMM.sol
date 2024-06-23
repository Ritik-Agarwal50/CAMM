// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "./Interface/IERC20.sol";

error InsufficientBalance();
error AmountShouldBeGreaterThanZero();

/**
 *VARIABLE
 1.  reserev0  :done
 2. reserev1:done
 totalSupply :done
    3.  balanceOf :done
    FUNNCTIONS
    4.  transfer :not needed
    5. mint :done
    6. burn :done
    7.update :done
    8. swap :done
    9. add Liq :done
    10. remove Liq :done
 */
contract CAMM {
    //INITIALIZATION
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    //VARIABLES
    uint256 public reserve0;
    uint256 public reserve1;
    mapping(address => uint) public balanceOf;
    uint256 public totalSupply;

    //CONSTRUCTOR
    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    //FUNCTIONS

    function _mint(address _to, uint256 amount) private {
        if (amount > 0) {
            revert AmountShouldBeGreaterThanZero();
        }
        balanceOf[_to] += amount;
        totalSupply += amount;
    }

    function burn(address _from, uint256 amount) private {
        if (amount > 0) {
            revert AmountShouldBeGreaterThanZero();
        }
        if (balanceOf[_from] >= amount) {
            revert InsufficientBalance();
        }
        balanceOf[_from] -= amount;
        totalSupply -= amount;
    }

    function update(uint256 _reserve0, uint256 _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    function swap(
        address _tokenIn,
        uint256 _amountIn
    ) external returns (uint256 amountOut) {
        require(
            _tokenIn == address(token0) || _tokenIn == address(token1),
            "Invalid token address"
        );

        bool isToken0 = _tokenIn == address(token0);

        (
            IERC20 tokenIn,
            IERC20 tokenOut,
            uint256 reserveIn,
            uint256 reserveOut
        ) = isToken0
                ? (token0, token1, reserve0, reserve1)
                : (token1, token0, reserve1, reserve0);

        tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        uint amountIn = tokenIn.balanceOf(address(this)) - reserveIn;
        amountOut = (amountIn * 997) / 1000;

        (uint256 res0, uint256 res1) = isToken0
            ? (reserveIn + amountIn, reserveOut - amountOut)
            : (reserveOut - amountOut, reserveIn + amountIn);

        update(res0, res1);
        tokenOut.transfer(msg.sender, amountOut);
    }

    function addLiquidity(
        uint256 _amount0,
        uint256 _amount1
    ) external returns (uint256 shares) {
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        uint256 bal0 = token0.balanceOf(address(this));
        uint256 bal1 = token1.balanceOf(address(this));

        uint256 d0 = bal0 - reserve0;
        uint256 d1 = bal1 - reserve1;

        if (totalSupply > 0) {
            shares = ((d0 + d1) * totalSupply) / (reserve0 + reserve1);
        } else {
            shares = d0 + d1;
        }

        require(shares > 0, "shares == 0 Sad :( ");
        _mint(msg.sender, shares);
        update(bal0, bal1);
    }

    function removeLiquidity(
        uint256 _shares
    ) external returns (uint256 d0, uint256 d1) {
        d0 = (reserve0 * _shares) / totalSupply;
        d1 = (reserve1 * _shares) / totalSupply;

        burn(msg.sender, _shares);
        update(reserve0 - d0, reserve1 - d1);

        if (d0 > 0) {
            token0.transfer(msg.sender, d0);
        }
        if (d1 > 0) {
            token1.transfer(msg.sender, d1);
        }
    }
}
