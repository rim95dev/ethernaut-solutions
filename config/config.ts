import { default as dotenv } from "dotenv";
import { ethers } from "ethers";
import { JsonRpcProvider } from "ethers/providers";

export const config = (level: number) => {
  dotenv.config({ quiet: true });

  const rpcUrl = process.env.RPC_URL;
  const privateKeys = process.env.PRIVATE_KEYS?.split(",") || [];
  const levelString = `${level > 9 ? "" : "0"}${level}`;
  const levelAddresses =
    process.env[`LEVEL_${levelString}_ADDRESSES`]?.split(",") || [];

  const rpc = new JsonRpcProvider(rpcUrl);
  const signers = privateKeys.map((e) => new ethers.Wallet(e, rpc));

  return {
    levelAddresses,
    rpc,
    signers,
  };
};
