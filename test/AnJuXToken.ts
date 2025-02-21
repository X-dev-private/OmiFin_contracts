import { expect } from "chai";
import { ethers } from "hardhat";

describe("AnJuXToken", function () {
  it("Deve permitir a mintagem após 24 horas", async function () {
    const [owner] = await ethers.getSigners();
    const AnJuXToken = await ethers.getContractFactory("AnJuXToken");
    const token = await AnJuXToken.deploy();
    await token.waitForDeployment();

    await token.mint(owner.address);
    const balance = await token.balanceOf(owner.address);
    expect(balance).to.equal(ethers.parseEther("0.40"));

    await expect(token.mint(owner.address)).to.be.revertedWith(
      "You have already minted recently. Please wait 24 hours."
    );
  });
});
