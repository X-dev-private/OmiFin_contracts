import { expect } from "chai";
import { ethers } from "hardhat";

describe("SimpleLiquidityPool", function () {
  let pool, anjux, ethof, owner, user;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    const AnJuXToken = await ethers.getContractFactory("AnJuXToken");
    const ETHoFToken = await ethers.getContractFactory("ETHoFToken");
    
    anjux = await AnJuXToken.deploy(owner.address);
    ethof = await ETHoFToken.deploy();
    
    const LiquidityPool = await ethers.getContractFactory("SimpleLiquidityPool");
    pool = await LiquidityPool.deploy(anjux.target, ethof.target, owner.address);
    
    await anjux.bridgeMint(owner.address, ethers.parseEther("10000"));
    await ethof.bridgeMint(owner.address, ethers.parseEther("10000"));
    await anjux.approve(pool.target, ethers.parseEther("1000"));
    await ethof.approve(pool.target, ethers.parseEther("1000"));
  });

  // ... outros testes permanecem iguais ...

  it("Deve realizar swaps entre AnJuX e ETHoF corretamente", async function () {
    await pool.addLiquidity(
      ethers.parseEther("1000"),
      ethers.parseEther("2000")
    );

    const amountIn = ethers.parseEther("100");
    await anjux.approve(pool.target, amountIn);
    
    const tx = await pool.swap(anjux.target, amountIn);
    
    // Verificação simplificada sem sinon
    await expect(tx)
      .to.emit(pool, "Swapped")
      .withArgs(
        owner.address,
        anjux.target,
        ethof.target,
        amountIn,
        expect.any(Number) // Usando a verificação nativa do Chai
      );
  });

  it("Deve lidar com swap de ETHoF para AnJuX", async function () {
    await pool.addLiquidity(
      ethers.parseEther("500"),
      ethers.parseEther("1000")
    );

    const amountIn = ethers.parseEther("200");
    await ethof.approve(pool.target, amountIn);
    
    await expect(pool.swap(ethof.target, amountIn))
      .to.emit(pool, "Swapped")
      .withArgs(
        owner.address,
        ethof.target,
        anjux.target,
        amountIn,
        expect.any(Number)
      );
  });
});