// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ETHoFToken is ERC20, Ownable {
    uint256 public mintAmount = 0.40 * 10 ** 18; // 0.40 token (com 18 casas decimais)
    uint256 public mintInterval = 24 hours; // Intervalo de 24 horas
    uint256 public feePercent = 1; // Taxa de 1% por transação
    address public feeReceiver; // Endereço que recebe as taxas
    bool public immutableMode = false; // Bloqueia mudanças futuras

    mapping(address => uint256) public lastMintTime;
    mapping(bytes32 => bool) public processedTransfers; // Guarda transferências processadas

    event TokensLocked(address indexed sender, uint256 amount, string targetChain, address targetAddress);
    event TokensUnlocked(address indexed recipient, uint256 amount, bytes32 txHash);
    event TokensBurned(address indexed burner, uint256 amount);

    constructor(address _feeReceiver) ERC20("ETHoF", "ETHoF") Ownable(msg.sender) {
        require(_feeReceiver != address(0), "Invalid fee receiver");
        _mint(msg.sender, 1_000_000 * 10 ** decimals()); // Criador recebe 1 milhão de tokens
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

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    function lockTokens(uint256 amount, string memory targetChain, address targetAddress) external {
        require(amount > 0, "Amount must be greater than zero");
        _transfer(msg.sender, address(this), amount);
        emit TokensLocked(msg.sender, amount, targetChain, targetAddress);
    }

    function unlockTokens(address recipient, uint256 amount, bytes32 txHash) external onlyOwner {
        require(!processedTransfers[txHash], "Transfer already processed");
        require(amount > 0, "Amount must be greater than zero");
        processedTransfers[txHash] = true;
        _transfer(address(this), recipient, amount);
        emit TokensUnlocked(recipient, amount, txHash);
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
}