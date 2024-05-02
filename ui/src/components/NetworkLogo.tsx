// components/NetworkLogo.tsx
import React from "react";
import { networks, NetworkName } from "../config";

interface NetworkLogoProps {
  network: NetworkName;
}

export const NetworkLogo = ({ network, ...props }: NetworkLogoProps & React.HTMLAttributes<HTMLSpanElement>) => {
  const n = networks[network];

  return (
    <span {...props}><n.icon /></span>
  );
};