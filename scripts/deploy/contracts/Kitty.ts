import { ethers as tsEthers } from "ethers";
import { Kitty__factory } from "../../../build/typechain";
import { Kitty } from "../../../build/typechain";
import { getSignerForDeployer } from "../utils";

export const contractNames = () => ["kitty"];

const deployKitty = async (
  signer?: tsEthers.Signer,
  waitCount = 1
) => {
  signer = signer ?? (await getSignerForDeployer());
  const Kitty = new Kitty__factory(signer);
  const contract = await Kitty.deploy();
  await contract.deployTransaction.wait(waitCount);
  return contract;
};

export const deploy = async (deployer, setAddresses) => {
  console.log("deploying Kitty");
  const kittyToken: Kitty = await deployKitty(deployer, 1);
  console.log(`deployed Kitty to address ${kittyToken.address}`);
  setAddresses({ kitty: kittyToken.address });
  return kittyToken;
};