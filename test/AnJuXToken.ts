import { expect } from "chai";
import { ethers } from "hardhat";

describe("AnJuXToken", function () {
  let token, owner, feeReceiver, user, newOwner;

  beforeEach(async function () {
    [owner, feeReceiver, user, newOwner] = await ethers.getSigners();
    const AnJuXToken = await ethers.getContractFactory("AnJuXToken");
    token = await AnJuXToken.deploy(feeReceiver.address);
    await token.waitForDeployment();
  });

  it("Deve permitir mintagem após 24 horas", async function () {
    await token.mint(owner.address);
    await expect(token.mint(owner.address)).to.be.revertedWith(
      "You have already minted recently. Please wait 24 hours."
    );
    
    // Avança o tempo
    await ethers.provider.send("evm_increaseTime", [24 * 60 * 60 + 1]);
    await ethers.provider.send("evm_mine", []);
    
    await expect(token.mint(owner.address)).to.emit(token, "Transfer");
  });

  it("Deve cobrar taxa de 1% nas transferências", async function () {
    const amount = ethers.parseEther("100");
    
    // Testa transfer simples
    await token.transfer(user.address, amount);
    expect(await token.balanceOf(user.address)).to.equal(ethers.parseEther("99"));
    expect(await token.balanceOf(feeReceiver.address)).to.equal(ethers.parseEther("1"));

    // Testa transferFrom
    await token.approve(user.address, amount);
    await token.connect(user).transferFrom(owner.address, user.address, amount);
    expect(await token.balanceOf(user.address)).to.equal(ethers.parseEther("198"));
  });

  it("Deve bloquear mudanças após ativar modo imutável", async function () {
    await token.lockOwnership();
    await expect(token.setFeePercent(2)).to.be.revertedWith("Contract is locked");
    await expect(token.transferOwnershipSecurely(newOwner.address))
      .to.be.revertedWith("Contract is locked");
  });

  it("Deve permitir bridgeMint apenas pelo owner", async function () {
    const amount = ethers.parseEther("500");
    await expect(token.connect(user).bridgeMint(user.address, amount))
      .to.be.revertedWithCustomError(token, "OwnableUnauthorizedAccount");

    await token.bridgeMint(user.address, amount);
    expect(await token.balanceOf(user.address)).to.equal(amount);
  });

  it("Deve atualizar taxas corretamente", async function () {
    await token.setFeePercent(5);
    expect(await token.feePercent()).to.equal(5);
    
    await token.lockOwnership();
    await expect(token.setFeePercent(10)).to.be.revertedWith("Contract is locked");
  });
});