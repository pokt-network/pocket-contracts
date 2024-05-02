import {
  networks,
  NetworkName,
} from "./config";

export const renderNetworkName = (network: NetworkName) => {
  return networks[network].name;
};



