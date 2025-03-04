// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ETHoFToken is ERC20, Ownable {
    uint256 public mintAmount = 0.40 * 10 ** 18;
    uint256 public mintInterval = 24 hours;
    uint256 public feePercent = 1;
    address public feeReceiver;
    bool public immutableMode = false;

    mapping(address => uint256) public lastMintTime;

    constructor(address _feeReceiver) ERC20("ETHoF", "ETHoF") Ownable(msg.sender) {
        require(_feeReceiver != address(0), "Invalid fee receiver");
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
        feeReceiver = _feeReceiver;
    }

    function mint(address to) external {
        require(block.timestamp >= lastMintTime[to] + mintInterval, "You have already minted recently. Please wait 24 hours.");
        lastMintTime[to] = block.timestamp;
        _mint(to, mintAmount);
    }

    function bridgeMint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function balanceOfETHoF(address account) external view returns (uint256) {
        return balanceOf(account);
    }

    function setFeePercent(uint256 _feePercent) external onlyOwner {
        require(!immutableMode, "Contract is locked");
        require(_feePercent <= 10, "Fee too high");
        feePercent = _feePercent;
    }

    function lockOwnership() external onlyOwner {
        require(!immutableMode, "Already locked");
        immutableMode = true;
    }

    function transferOwnershipSecurely(address newOwner) external onlyOwner {
        require(!immutableMode, "Contract is locked");
        require(newOwner != address(0), "Invalid owner address");
        _transferOwnership(newOwner);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * feePercent) / 100;
        uint256 amountAfterFee = amount - fee;

        super.transfer(feeReceiver, fee);
        return super.transfer(recipient, amountAfterFee);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * feePercent) / 100;
        uint256 amountAfterFee = amount - fee;

        super.transferFrom(sender, feeReceiver, fee);
        return super.transferFrom(sender, recipient, amountAfterFee);
    }

    function approveSpender(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
}
