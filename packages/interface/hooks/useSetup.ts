import { ALICE } from "@/constants";
import { useEnvironment } from "@/contexts/environment";
import { testClient, walletClient } from "@/pages/_app";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import MockERC20 from "dry-powder/out//MockERC20.sol/MockERC20.json";
import { createErc20 } from "reverse-mirage";
import invariant from "tiny-invariant";
import { type Hex, parseEther } from "viem";
import { useChainId, usePublicClient } from "wagmi";
import { mockErc20ABI } from "../generated";

export const useSetup = () => {
  const publicClient = usePublicClient();
  const queryClient = useQueryClient();
  const chainID = useChainId();
  const { id, setID, setToken } = useEnvironment();

  return useMutation({
    mutationFn: async () => {
      if (id === undefined) {
        const deployHash = await walletClient.deployContract({
          account: ALICE,
          abi: mockErc20ABI,
          bytecode: MockERC20.bytecode.object as Hex,
          args: ["Marshall Rogan INU", "MRI", 18],
        });

        const { contractAddress } =
          await publicClient.waitForTransactionReceipt({
            hash: deployHash,
          });
        invariant(contractAddress);

        setToken({
          ...createErc20(contractAddress, "Mock ERC", "MOCK", 18, chainID),
          logoURI:
            "https://assets.coingecko.com/coins/images/23784/small/mri.png?1647693409",
        });

        const mintHash = await walletClient.writeContract({
          abi: mockErc20ABI,
          functionName: "mint",
          address: contractAddress,
          args: [ALICE, parseEther("10")],
        });
        await publicClient.waitForTransactionReceipt({ hash: mintHash });

        setID(await testClient.snapshot());
      } else {
        await testClient.revert({ id });
        setID(await testClient.snapshot());
        await queryClient.invalidateQueries();
      }
    },
  });
};
