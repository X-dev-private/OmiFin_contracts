    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;
    
    import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";
    
    contract TokenFactory is Ownable {
    event TokenCreated(address indexed tokenAddress, string name, string symbol, address feeReceiver, uint256 initialSupply, address creator);

    mapping(address => address[]) public ownerTokens;
    mapping(address => bool) public isTokenFromFactory;
    address[] public allTokens;

    constructor() Ownable(msg.sender) {}

    function createToken(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) external returns (address) {
        CustomToken newToken = new CustomToken(name, symbol, owner(), msg.sender, initialSupply);
        address tokenAddress = address(newToken);

        ownerTokens[msg.sender].push(tokenAddress);
        allTokens.push(tokenAddress);
        isTokenFromFactory[tokenAddress] = true;

        emit TokenCreated(tokenAddress, name, symbol, owner(), initialSupply, msg.sender);
        return tokenAddress;
    }

    function getTokenByAddress(address tokenAddress) external view returns (
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address owner,
        bool isValid
    ) {
        isValid = isTokenFromFactory[tokenAddress];
        if (!isValid) {
            return ("", "", 0, address(0), false);
        }

        try ERC20(tokenAddress).name() returns (string memory tokenName) {
            name = tokenName;
        } catch {
            name = "Error";
        }

        try ERC20(tokenAddress).symbol() returns (string memory tokenSymbol) {
            symbol = tokenSymbol;
        } catch {
            symbol = "Error";
        }

        try ERC20(tokenAddress).totalSupply() returns (uint256 supply) {
            totalSupply = supply;
        } catch {
            totalSupply = 0;
        }

        try Ownable(tokenAddress).owner() returns (address tokenOwner) {
            owner = tokenOwner;
        } catch {
            owner = address(0);
        }

        return (name, symbol, totalSupply, owner, true);
    }

    // Função para obter os tokens criados por um usuário específico
    function getTokenByOwner(address owner) external view returns (address[] memory) {
        uint256 count = 0;

        // Primeiro, contamos quantos tokens pertencem ao owner
        for (uint256 i = 0; i < allTokens.length; i++) {
            try Ownable(allTokens[i]).owner() returns (address tokenOwner) {
                if (tokenOwner == owner) {
                    count++;
                }
            } catch {
                continue; // Se falhar, ignora o token
            }
        }

        // Criamos um array com o tamanho correto
        address[] memory ownedTokens = new address[](count);
        uint256 index = 0;

        // Preenchemos o array com os endereços dos tokens
        for (uint256 i = 0; i < allTokens.length; i++) {
            try Ownable(allTokens[i]).owner() returns (address tokenOwner) {
                if (tokenOwner == owner) {
                    ownedTokens[index] = allTokens[i];
                    index++;
                }
            } catch {
                continue;
            }
        }

        return ownedTokens;
    }

    function getAllTokenSymbols() external view returns (string[] memory) {
        string[] memory symbols = new string[](allTokens.length);

        for (uint256 i = 0; i < allTokens.length; i++) {
            ERC20 token = ERC20(allTokens[i]);
            symbols[i] = token.symbol();
        }

        return symbols;
    }

    
}

contract CustomToken is ERC20, Ownable {
    uint256 public mintInterval = 24 hours;
    uint256 public constant feePercent = 1;
    address public feeReceiver;
    bool public immutableMode = false;
    bool public mintEnabled = false;
    uint256 public mintAmount = 0.40 * 10 ** 18;

    mapping(address => uint256) public lastMintTime;
    uint256 public totalBurned;

    event TokensBurned(address indexed burner, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        address _feeReceiver,
        address _owner,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(_owner) {
        require(_feeReceiver != address(0), "Invalid fee receiver");
        _mint(_owner, initialSupply * 10 ** decimals());
        feeReceiver = _feeReceiver;
    }

    function burn(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _burn(msg.sender, amount);
        totalBurned += amount;
        emit TokensBurned(msg.sender, amount);
    }

    function mint(address to) external {
        require(mintEnabled, "Mint is disabled");
        require(block.timestamp >= lastMintTime[to] + mintInterval, "You have already minted recently. Please wait 24 hours.");
        lastMintTime[to] = block.timestamp;
        _mint(to, mintAmount);
    }

    function setMintAmount(uint256 _mintAmount) external onlyOwner {
        require(!immutableMode, "Contract is locked");
        require(_mintAmount > 0, "Mint amount must be greater than 0");
        mintAmount = _mintAmount;
    }

    function setMintEnabled(bool _mintEnabled) external onlyOwner {
        require(!immutableMode, "Contract is locked");
        mintEnabled = _mintEnabled;
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
