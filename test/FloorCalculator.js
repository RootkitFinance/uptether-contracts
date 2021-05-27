const { expect } = require("chai");
const { utils, constants, BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const { createWETH, createUniswap } = require("./helpers");

const parseTether = (value) => value + "000000"

describe("FloorCalculator", function() {
    let owner, uniswap, rooted, base, elite, floorCalculator;

    beforeEach(async function() {
        [owner] = await ethers.getSigners();
        uniswap = await createUniswap(owner);
        const baseFactory = await ethers.getContractFactory("TetherTest");
        base = await baseFactory.connect(owner).deploy();
        const eliteFactory = await ethers.getContractFactory("EliteToken");
        elite = await eliteFactory.connect(owner).deploy(base.address);       
        const rootedFactory = await ethers.getContractFactory("RootedToken");
        rooted = await rootedFactory.connect(owner).deploy();
        const floorCalculatorFactory = await ethers.getContractFactory("FloorCalculator");
        floorCalculator = await floorCalculatorFactory.deploy(rooted.address, uniswap.factory.address);
        await rooted.connect(owner).setMinter(owner.address);
        await rooted.connect(owner).mint(utils.parseEther("0.0000000002"));
    })

    describe("pair has 5000 Rooted & 1 Elite", function() {
        beforeEach(async function() {
            await base.connect(owner).approve(elite.address, constants.MaxUint256);
            await elite.connect(owner).approve(uniswap.router.address, constants.MaxUint256);
            await rooted.connect(owner).approve(uniswap.router.address, constants.MaxUint256);
            await elite.connect(owner).depositTokens(parseTether("100"));
            await uniswap.router.connect(owner).addLiquidity(rooted.address, elite.address, utils.parseEther("100"), parseTether("100"), utils.parseEther("100"), parseTether("100"), owner.address, 2e9);
        })

        it("subfloor is approx 0.5", async function() {
            const subFloor = BigNumber.from(await floorCalculator.calculateSubFloor(base.address, elite.address));
            expect(subFloor).to.equal("50075113");
        })
    })
});