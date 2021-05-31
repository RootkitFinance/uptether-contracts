const { expect } = require("chai");
const { utils, constants, BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const { createWETH, createUniswap } = require("./helpers");

describe("ClaimableAirdrop", function() {
    let owner, user1, user2, user3, rooted, claimableAirdrop;

    beforeEach(async function() {
        [owner, user1, user2, user3] = await ethers.getSigners();
        const rootedFactory = await ethers.getContractFactory("RootedToken");
        rooted = await rootedFactory.connect(owner).deploy();
        const claimableAirdropFactory = await ethers.getContractFactory("ClaimableAirdrop");
        claimableAirdrop = await claimableAirdropFactory.deploy(rooted.address);
        await rooted.connect(owner).setMinter(owner.address);
        await rooted.connect(owner).mint(utils.parseEther("100"));
        await rooted.connect(owner).transfer(claimableAirdrop.address, utils.parseEther("100"));
    })

    describe("set airdrop addresses and amounts", function() {
        beforeEach(async function() {
            await claimableAirdrop.connect(owner).setAddressesAndAmounts([user1.address, user2.address], [utils.parseEther("69"), utils.parseEther("1")]);
        })

        it("initialized as expected", async function() {
            expect(await claimableAirdrop.claimableTokens(user1.address)).to.equal(utils.parseEther("69"));
            expect(await claimableAirdrop.claimableTokens(user2.address)).to.equal(utils.parseEther("1"));
            expect(await claimableAirdrop.claimableTokens(user3.address)).to.equal("0");
        })       

        it("claims as expected", async function() {
            await claimableAirdrop.connect(user1).claim();
            expect(await claimableAirdrop.claimableTokens(user1.address)).to.equal("0");
            expect(await rooted.balanceOf(user1.address)).to.equal(utils.parseEther("69"));

            await claimableAirdrop.connect(user2).claim();
            expect(await claimableAirdrop.claimableTokens(user2.address)).to.equal("0");
            expect(await rooted.balanceOf(user2.address)).to.equal(utils.parseEther("1"));

        })

        it("reverts when nothing to claim", async function() {
            await expect(claimableAirdrop.connect(user3).claim()).to.be.revertedWith("Nothing to claim");
        })
    })
});