import { ethers as tsEthers } from "ethers";
import * as Kitty from "./Kitty";

export interface DeploymentModule {
  contractNames: (...params: any) => string[];
  deploy: (
    deployer: tsEthers.Signer,
    setAddresses: Function,
    addresses?: any
  ) => Promise<tsEthers.Contract>;
  upgrade?: (deployer: tsEthers.Signer, addresses?: any) => void;
}

const modules: DeploymentModule[] = [Kitty];

export default modules;