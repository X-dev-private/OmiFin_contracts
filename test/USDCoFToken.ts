import { expect } from "chai";
import { ethers } from "hardhat";

describe("USDCoFToken", function () {
  it("Deve permitir a mintagem após 24 horas", async function () {
    const [owner, feeReceiver] = await ethers.getSigners();

    // Deploy do contrato USDCoFToken
    const USDCoFToken = await ethers.getContractFactory("USDCoFToken");
    const token = await USDCoFToken.deploy(feeReceiver.address); // Passa o endereço do feeReceiver
    await token.waitForDeployment();

    // Verifica o saldo inicial do owner (1 milhão de tokens)
    const initialBalance = await token.balanceOf(owner.address);
    expect(initialBalance).to.equal(ethers.parseEther("1000000"));

    // Primeira mintagem
    await token.mint(owner.address);
    let balance = await token.balanceOf(owner.address);
    expect(balance).to.equal(ethers.parseEther("1000000.40")); // Verifica se o saldo é 1.000.000,40 tokens

    // Tenta mintar novamente antes de 24 horas
    await expect(token.mint(owner.address)).to.be.revertedWith(
      "You have already minted recently. Please wait 24 hours."
    );

    // Avança o tempo em 24 horas
    await ethers.provider.send("evm_increaseTime", [24 * 60 * 60]); // Avança 24 horas
    await ethers.provider.send("evm_mine", []); // Mina um novo bloco

    // Tenta mintar novamente após 24 horas
    await token.mint(owner.address);
    balance = await token.balanceOf(owner.address);
    expect(balance).to.equal(ethers.parseEther("1000000.80")); // Verifica se o saldo é 1.000.000,80 tokens
  });

  it("Deve cobrar uma taxa de 1% nas transferências", async function () {
    const [owner, feeReceiver, recipient] = await ethers.getSigners();

    // Deploy do contrato USDCoFToken
    const USDCoFToken = await ethers.getContractFactory("USDCoFToken");
    const token = await USDCoFToken.deploy(feeReceiver.address); // Passa o endereço do feeReceiver
    await token.waitForDeployment();

    // Transfere tokens do owner para o recipient
    const transferAmount = ethers.parseEther("100"); // 100 tokens
    await token.transfer(recipient.address, transferAmount);

    // Verifica o saldo do recipient após a transferência
    const recipientBalance = await token.balanceOf(recipient.address);
    expect(recipientBalance).to.equal(ethers.parseEther("99")); // 99 tokens (1% de taxa)

    // Verifica o saldo do feeReceiver
    const feeReceiverBalance = await token.balanceOf(feeReceiver.address);
    expect(feeReceiverBalance).to.equal(ethers.parseEther("1")); // 1 token (taxa de 1%)
  });

  it("Deve bloquear mudanças após ativar o modo imutável", async function () {
    const [owner, feeReceiver, newOwner] = await ethers.getSigners();

    // Deploy do contrato USDCoFToken
    const USDCoFToken = await ethers.getContractFactory("USDCoFToken");
    const token = await USDCoFToken.deploy(feeReceiver.address); // Passa o endereço do feeReceiver
    await token.waitForDeployment();

    // Ativa o modo imutável
    await token.lockOwnership();

    // Tenta mudar a taxa de transferência (deve falhar)
    await expect(token.setFeePercent(2)).to.be.revertedWith("Contract is locked");

    // Tenta transferir a propriedade (deve falhar)
    await expect(token.transferOwnershipSecurely(newOwner.address)).to.be.revertedWith("Contract is locked");
  });
});