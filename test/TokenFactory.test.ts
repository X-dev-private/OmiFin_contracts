import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { TokenFactory, CustomToken } from "../typechain-types";

describe("TokenFactory and CustomToken", function () {
  let tokenFactory: TokenFactory;
  let customToken: CustomToken;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  const tokenName = "MyToken";
  const tokenSymbol = "MTK";
  const initialSupply = ethers.utils.parseEther("1000000"); // 1 milhão de tokens
  const mintAmount = ethers.utils.parseEther("0.40"); // 0.40 tokens

  before(async function () {
    // Obter contas
    [owner, user1, user2] = await ethers.getSigners();

    // Implantar TokenFactory
    const TokenFactoryFactory = await ethers.getContractFactory("TokenFactory");
    tokenFactory = (await TokenFactoryFactory.deploy()) as TokenFactory;
    await tokenFactory.deployed();

    // Criar um novo token usando a TokenFactory
    const tx = await tokenFactory.createToken(tokenName, tokenSymbol, initialSupply);
    const receipt = await tx.wait();
    const tokenAddress = receipt.events?.find((e) => e.event === "TokenCreated")?.args?.tokenAddress;

    // Obter instância do CustomToken
    const CustomTokenFactory = await ethers.getContractFactory("CustomToken");
    customToken = CustomTokenFactory.attach(tokenAddress) as CustomToken;
  });

  it("Should deploy TokenFactory and create a new token", async function () {
    expect(await customToken.name()).to.equal(tokenName);
    expect(await customToken.symbol()).to.equal(tokenSymbol);
    expect(await customToken.balanceOf(owner.address)).to.equal(initialSupply);
  });

  it("Should not allow minting if mintEnabled is false", async function () {
    await expect(customToken.mint(user1.address)).to.be.revertedWith("Mint is disabled");
  });

  it("Should allow owner to enable minting", async function () {
    await customToken.setMintEnabled(true);
    expect(await customToken.mintEnabled()).to.equal(true);
  });

  it("Should allow users to mint tokens after minting is enabled", async function () {
    await customToken.mint(user1.address);
    expect(await customToken.balanceOf(user1.address)).to.equal(mintAmount);

    // Verificar se o intervalo de mint é respeitado
    await expect(customToken.mint(user1.address)).to.be.revertedWith("You have already minted recently. Please wait 24 hours.");
  });

  it("Should allow owner to change mintAmount", async function () {
    const newMintAmount = ethers.utils.parseEther("1.0");
    await customToken.setMintAmount(newMintAmount);
    expect(await customToken.mintAmount()).to.equal(newMintAmount);
  });

  it("Should apply a 1% fee on transfers", async function () {
    const transferAmount = ethers.utils.parseEther("100");
    const fee = transferAmount.mul(1).div(100); // 1% de taxa
    const amountAfterFee = transferAmount.sub(fee);

    // Transferir tokens de owner para user2
    await customToken.transfer(user2.address, transferAmount);

    // Verificar saldos
    expect(await customToken.balanceOf(owner.address)).to.equal(initialSupply.sub(transferAmount));
    expect(await customToken.balanceOf(user2.address)).to.equal(amountAfterFee);
    expect(await customToken.balanceOf(customToken.feeReceiver())).to.equal(fee);
  });

  it("Should allow owner to lock the contract", async function () {
    await customToken.lockOwnership();
    expect(await customToken.immutableMode()).to.equal(true);

    // Verificar se o contrato está bloqueado para mudanças
    await expect(customToken.setMintAmount(ethers.utils.parseEther("0.50"))).to.be.revertedWith("Contract is locked");
    await expect(customToken.setMintEnabled(false)).to.be.revertedWith("Contract is locked");
  });

  it("Should allow owner to transfer ownership securely", async function () {
    await customToken.transferOwnershipSecurely(user1.address);
    expect(await customToken.owner()).to.equal(user1.address);
  });
});