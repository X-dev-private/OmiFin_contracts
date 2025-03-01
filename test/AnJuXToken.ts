import { expect } from "chai";
import { ethers } from "hardhat";

describe("AnJuXToken", function () {
  let token, owner, feeReceiver, recipient, newOwner;

  beforeEach(async function () {
    [owner, feeReceiver, recipient, newOwner] = await ethers.getSigners();
    const AnJuXToken = await ethers.getContractFactory("AnJuXToken");
    token = await AnJuXToken.deploy(feeReceiver.address);
    await token.waitForDeployment();
  });

  it("Deve permitir a mintagem após 24 horas", async function () {
    await token.mint(owner.address);
    await expect(token.mint(owner.address)).to.be.revertedWith(
      "You have already minted recently. Please wait 24 hours."
    );
    await ethers.provider.send("evm_increaseTime", [24 * 60 * 60]);
    await ethers.provider.send("evm_mine", []);
    await token.mint(owner.address);
  });

  it("Deve cobrar uma taxa de 1% nas transferências", async function () {
    const transferAmount = ethers.parseEther("100");
    await token.transfer(recipient.address, transferAmount);
    expect(await token.balanceOf(recipient.address)).to.equal(ethers.parseEther("99"));
    expect(await token.balanceOf(feeReceiver.address)).to.equal(ethers.parseEther("1"));
  });

  it("Deve bloquear mudanças após ativar o modo imutável", async function () {
    await token.lockOwnership();
    await expect(token.setFeePercent(2)).to.be.revertedWith("Contract is locked");
    await expect(token.transferOwnershipSecurely(newOwner.address)).to.be.revertedWith("Contract is locked");
  });

  it("Deve permitir queimar tokens", async function () {
    const burnAmount = ethers.parseEther("10");
    await token.burn(burnAmount);
    expect(await token.balanceOf(owner.address)).to.equal(ethers.parseEther("999990"));
  });

  it("Deve permitir lock e unlock de tokens na bridge", async function () {
    const lockAmount = ethers.parseEther("50");
    const txHash = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"; // txHash válido
    await token.lockTokens(lockAmount, "ChainB", recipient.address);
    expect(await token.balanceOf(owner.address)).to.equal(ethers.parseEther("999950"));
    await token.unlockTokens(recipient.address, lockAmount, txHash);
    expect(await token.balanceOf(recipient.address)).to.equal(ethers.parseEther("50"));
  });

  it("Deve permitir bridgeMint somente pelo owner", async function () {
    const mintAmount = ethers.parseEther("200");
    await token.bridgeMint(recipient.address, mintAmount);
    expect(await token.balanceOf(recipient.address)).to.equal(mintAmount);

    // Verifica se a função reverte com o custom error "OwnableUnauthorizedAccount"
    await expect(
      token.connect(recipient).bridgeMint(recipient.address, mintAmount)
    ).to.be.revertedWithCustomError(token, "OwnableUnauthorizedAccount");
  });
});