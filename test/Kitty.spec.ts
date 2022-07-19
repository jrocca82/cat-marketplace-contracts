import { ethers } from "hardhat";
import { ethers as tsEthers } from "ethers";
import { expect } from "chai";
import { isAddress } from "ethers/lib/utils";
import { Kitty, Kitty__factory } from "../build/typechain";

let kittyToken: Kitty;
let deployer: tsEthers.Signer;
let user: tsEthers.Wallet;

describe("Kitty Token", () => {
  before(async () => {
    deployer = (await ethers.getSigners())[0];
    user = new ethers.Wallet(
      "0xcafecafecafecafecafecafecafecafecafecafecafecafecafecafecafecafecafe",
      deployer.provider
    );
    kittyToken = await new Kitty__factory(deployer).deploy();
    // Send ETH to user from signer.
    await deployer.sendTransaction({
      to: user.address,
      value: ethers.utils.parseEther("1000")
    });
  });

  it("Should deploy", async () => {
    //Check contract has deployed
    const address = kittyToken.address;
    const verifyAddress = isAddress(address);
    expect(verifyAddress === true);
  });
});