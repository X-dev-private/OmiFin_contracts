// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenFactory is Ownable {
    event TokenCreated(address indexed tokenAddress, string name, string symbol, address feeReceiver, uint256 initialSupply);

    constructor() Ownable(msg.sender) {}

    function createToken(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) external onlyOwner returns (address) {
        // O owner da factory será o feeReceiver de todos os tokens criados
        CustomToken newToken = new CustomToken(name, symbol, owner(), initialSupply);
        emit TokenCreated(address(newToken), name, symbol, owner(), initialSupply);
        return address(newToken);
    }
}

contract CustomToken is ERC20, Ownable {
    uint256 public mintInterval = 24 hours;
    uint256 public constant feePercent = 1; // Taxa fixa de 1% por transação
    address public feeReceiver; // Endereço que recebe as taxas
    bool public immutableMode = false; // Bloqueia mudanças futuras
    bool public mintEnabled = false; // Controla se a função mint está habilitada (inicialmente desabilitada)
    uint256 public mintAmount = 0.40 * 10 ** 18; // Quantidade de tokens que podem ser mintados por vez

    mapping(address => uint256) public lastMintTime;

    constructor(
        string memory name,
        string memory symbol,
        address _feeReceiver,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(msg.sender) {
        require(_feeReceiver != address(0), "Invalid fee receiver");
        _mint(msg.sender, initialSupply * 10 ** decimals()); // Criador recebe o supply inicial
        feeReceiver = _feeReceiver;
    }

    // Função mint só é executada se mintEnabled for true
    function mint(address to) external {
        require(mintEnabled, "Mint is disabled"); // Verifica se o mint está habilitado
        require(block.timestamp >= lastMintTime[to] + mintInterval, "You have already minted recently. Please wait 24 hours.");
        lastMintTime[to] = block.timestamp;
        _mint(to, mintAmount);
    }

    // Função para alterar o mintAmount
    function setMintAmount(uint256 _mintAmount) external onlyOwner {
        require(!immutableMode, "Contract is locked");
        require(_mintAmount > 0, "Mint amount must be greater than 0");
        mintAmount = _mintAmount;
    }

    // Função para habilitar ou desabilitar o mint
    function setMintEnabled(bool _mintEnabled) external onlyOwner {
        require(!immutableMode, "Contract is locked");
        mintEnabled = _mintEnabled;
    }

    // Bloqueia mudanças futuras no contrato
    function lockOwnership() external onlyOwner {
        require(!immutableMode, "Already locked");
        immutableMode = true;
    }

    // Transfere a propriedade do contrato de forma segura
    function transferOwnershipSecurely(address newOwner) external onlyOwner {
        require(!immutableMode, "Contract is locked");
        require(newOwner != address(0), "Invalid owner address");
        _transferOwnership(newOwner);
    }

    // Função de transferência com taxa de 1%
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * feePercent) / 100;
        uint256 amountAfterFee = amount - fee;

        super.transfer(feeReceiver, fee);
        return super.transfer(recipient, amountAfterFee);
    }

    // Função de transferFrom com taxa de 1%
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * feePercent) / 100;
        uint256 amountAfterFee = amount - fee;

        super.transferFrom(sender, feeReceiver, fee);
        return super.transferFrom(sender, recipient, amountAfterFee);
    }
}