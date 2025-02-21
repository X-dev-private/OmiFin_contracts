// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ETHoFToken is ERC20 {
    uint256 public mintAmount = 0.40 * 10 ** 18; // 0.40 token (com 18 casas decimais)
    uint256 public mintInterval = 24 hours; // Intervalo de 24 horas

    mapping(address => uint256) public lastMintTime;

    constructor() ERC20("ETHoF", "ETHoF") {}

    function mint(address to) external {
        require(block.timestamp >= lastMintTime[to] + mintInterval, "You have already minted recently. Please wait 24 hours.");
        
        lastMintTime[to] = block.timestamp;
        _mint(to, mintAmount);
    }

    function balanceOfETHoF(address account) external view returns (uint256) {
        return balanceOf(account);
    }
}
