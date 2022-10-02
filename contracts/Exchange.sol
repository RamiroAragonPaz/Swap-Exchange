// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {


    address public cryptoDevTokenAddress;

    constructor(address _CryptoDevToken) ERC20("CriptoDev LP Token", "CDLP"){
        require (_CryptoDevToken != address(0), "Token address passed is a null address");
        cryptoDevTokenAddress = _CryptoDevToken;
    }

    function getReserve() public view returns(uint256 ){
        return ERC20(cryptoDevTokenAddress).balanceOf(address(this));
    }

    //Liquidity to the contract

    function addLiquidity(uint256 _amount) public payable returns(uint256){
        uint256 liquidity;
        uint256 ethBalance = address(this).balance;
        uint cryptoDevTokenReserve = getReserve();
        ERC20 cryptoDevToken = ERC20(cryptoDevTokenAddress);

        if(cryptoDevTokenReserve == 0 ) {
            cryptoDevToken.transferFrom(msg.sender, address(this), _amount);
            liquidity = ethBalance;
            _mint(msg.sender, liquidity);
        } else {
            uint256 ethReserve = ethBalance - msg.value;
            uint256 cryptoDevTokenAmount = (msg.value * cryptoDevTokenReserve)/(ethReserve);
            require(_amount >= cryptoDevTokenAmount, "Amount of tokens sent is less than the minimum tokens required");
            cryptoDevToken.transferFrom(msg.sender, address(this), cryptoDevTokenAmount);
            liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
        }
        return liquidity;
    }

    //Remove liquidity of the contract

    function removeLiquidity(uint256 _amount) public returns(uint256, uint256){
        require(_amount > 0, "_amount is equal than zero");
        uint256 ethReserve = address(this).balance;
        uint256 _totalSupply = totalSupply();
        uint256 ethAmount = (ethReserve * _amount)/_totalSupply;
        uint256 cryptoDevTokenAmount = (getReserve() * _amount);
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        ERC20(cryptoDevTokenAddress).transfer(msg.sender, cryptoDevTokenAmount);
        return (ethAmount, cryptoDevTokenAmount);
        }

    //Eth/CryptoDevTokens to be returned

    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve) public pure returns(uint256){
            require(inputAmount > 0 && outputReserve >0, "invalid reserves");
            uint256 inputAmountWithFee = (inputAmount * 99);
            uint256 numerator = inputAmountWithFee * outputReserve;
            uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
            return numerator/denominator;
        }

        //Swaps Eth for CryptoDev

        function ethToCryptoDevToken(uint256 _minTokens) public payable{
            uint256 tokenReserve = getReserve();
            uint256 tokensBougth = getAmountOfTokens(
                msg.value,
                address(this).balance,
                tokenReserve
                );
                require(tokensBougth >= _minTokens, "insufficient output amount");
                ERC20(cryptoDevTokenAddress).transfer(msg.sender, tokensBougth);
        }

        //Swaps CryptoDev fot Eth

        function cryptoDevTokenForEth(uint256 _tokensSold, uint256 _minEth) public {
            uint256 tokenReserve = getReserve();
            uint256 ethBougth = getAmountOfTokens(
                _tokensSold,
                tokenReserve,
                address(this).balance
                );
                require(ethBougth >= _minEth, "insufficient output amount");
                ERC20(cryptoDevTokenAddress).transferFrom(
                    address(this), 
                    msg.sender, 
                    _tokensSold
                    );
                payable(msg.sender).transfer(ethBougth);



        }


}