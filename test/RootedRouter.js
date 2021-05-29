const { expect } = require("chai");
const { utils, constants, BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const { createWETH, createUniswap } = require("./helpers");

const parseTether = (value) => value + "000000"

describe("RootedRouter", function() {
    let owner, uniswap, rooted, base, elite, router;

    beforeEach(async function() {
        [owner] = await ethers.getSigners();
        uniswap = await createUniswap(owner);
        const baseFactory = await ethers.getContractFactory("TetherTest");
        base = await baseFactory.connect(owner).deploy();
        const eliteFactory = await ethers.getContractFactory("EliteToken");
        elite = await eliteFactory.connect(owner).deploy(base.address);       
        const rootedFactory = await ethers.getContractFactory("RootedToken");
        rooted = await rootedFactory.connect(owner).deploy();
        const routerFactory = await ethers.getContractFactory("RootedRouter");
        router = await routerFactory.deploy(elite.address, rooted.address, uniswap.router.address);
        await rooted.connect(owner).setMinter(owner.address);
        await rooted.connect(owner).mint(utils.parseEther("0.0000000001"));

        console.log(utils.formatEther(await rooted.balanceOf(owner.address)));
        console.log(utils.formatUnits((await base.balanceOf(owner.address)).toString(), 6));

        await base.connect(owner).approve(elite.address, constants.MaxUint256);
        await elite.connect(owner).depositTokens(utils.parseUnits("10", 6));
        console.log(utils.formatUnits((await elite.balanceOf(owner.address)).toString(), 6));

        await uniswap.factory.createPair(elite.address, rooted.address);
        await base.connect(owner).approve(router.address, constants.MaxUint256);
        await rooted.connect(owner).approve(router.address, constants.MaxUint256);

        await elite.connect(owner).approve(uniswap.router.address, constants.MaxUint256);
        await rooted.connect(owner).approve(uniswap.router.address, constants.MaxUint256);

        await uniswap.router.connect(owner).addLiquidity(elite.address, rooted.address, utils.parseUnits("5", 6), utils.parseEther("5"), 0,  0, owner.address, 2e9);
        const pair = uniswap.pairFor(await uniswap.factory.getPair(elite.address, rooted.address));

        const rootedTransferGateFactory = await ethers.getContractFactory("RootedTransferGate");        
        const rootedTransferGate = await rootedTransferGateFactory.connect(owner).deploy(rooted.address, uniswap.router.address);
        
        await rooted.connect(owner).setTransferGate(rootedTransferGate.address);
        await rooted.connect(owner).setLiquidityController(rootedTransferGate.address, true);
        await rootedTransferGate.connect(owner).setUnrestrictedController(router.address, true);
        await rootedTransferGate.connect(owner).setMainPool(pair.address);
    })

    it("buys", async function() {
        console.log(utils.formatEther(await rooted.balanceOf(owner.address)));
        await router.connect(owner).buyRooted(utils.parseUnits("1", 6), 0, owner.address);
        console.log(utils.formatEther(await rooted.balanceOf(owner.address)));
    })

    it("sells", async function() {
        console.log(utils.formatEther(await rooted.balanceOf(owner.address)));
        await router.connect(owner).sellRooted(utils.parseEther("1"), 0, owner.address);
        console.log(utils.formatEther(await rooted.balanceOf(owner.address)));
    })
});