import { ethers } from "ethers";

/**
 * EIP-712 Type definitions for ERC-3009 transferWithAuthorization
 */
export const EIP712_DOMAIN_TYPE = [
  { name: "name", type: "string" },
  { name: "version", type: "string" },
  { name: "chainId", type: "uint256" },
  { name: "verifyingContract", type: "address" },
];

export const TRANSFER_WITH_AUTHORIZATION_TYPE = [
  { name: "from", type: "address" },
  { name: "to", type: "address" },
  { name: "value", type: "uint256" },
  { name: "validAfter", type: "uint256" },
  { name: "validBefore", type: "uint256" },
  { name: "nonce", type: "bytes32" },
];

/**
 * Payment Requirements Generator
 * Generates EIP-712 signing requirements for gasless payments
 */
export class PaymentHelper {
  /**
   * Generate a unique nonce for payment authorization
   * @returns Random bytes32 nonce
   */
  static generateNonce(): string {
    return ethers.hexlify(ethers.randomBytes(32));
  }

  /**
   * Generate EIP-712 typed data for transferWithAuthorization
   * @param params Payment parameters
   * @returns EIP-712 typed data for signing
   */
  static generateTypedData(params: {
    from: string;
    to: string;
    value: bigint;
    validAfter: bigint;
    validBefore: bigint;
    nonce: string;
    tokenName: string;
    tokenVersion: string;
    chainId: number;
    verifyingContract: string;
  }) {
    return {
      types: {
        EIP712Domain: EIP712_DOMAIN_TYPE,
        TransferWithAuthorization: TRANSFER_WITH_AUTHORIZATION_TYPE,
      },
      domain: {
        name: params.tokenName,
        version: params.tokenVersion,
        chainId: params.chainId,
        verifyingContract: params.verifyingContract,
      },
      primaryType: "TransferWithAuthorization",
      message: {
        from: params.from,
        to: params.to,
        value: params.value.toString(),
        validAfter: params.validAfter.toString(),
        validBefore: params.validBefore.toString(),
        nonce: params.nonce,
      },
    };
  }

  /**
   * Generate signing request for frontend
   * @param buyer Buyer's wallet address
   * @param provider Content provider's address
   * @param amount Payment amount
   * @param tokenAddress Payment token contract address
   * @param tokenName Token name (e.g., "PaymentToken")
   * @param tokenVersion Token version (e.g., "1")
   * @param chainId Chain ID (e.g., Dispatch testnet chain ID)
   * @returns Signing request object for frontend
   */
  static generateSigningRequest(
    buyer: string,
    provider: string,
    amount: bigint,
    tokenAddress: string,
    tokenName: string,
    tokenVersion: string,
    chainId: number
  ) {
    const nonce = this.generateNonce();
    const now = Math.floor(Date.now() / 1000);
    const validAfter = BigInt(now); // Valid immediately
    const validBefore = BigInt(now + 3600); // Valid for 1 hour

    const typedData = this.generateTypedData({
      from: buyer,
      to: provider,
      value: amount,
      validAfter,
      validBefore,
      nonce,
      tokenName,
      tokenVersion,
      chainId,
      verifyingContract: tokenAddress,
    });

    return {
      typedData,
      params: {
        from: buyer,
        to: provider,
        value: amount.toString(),
        validAfter: validAfter.toString(),
        validBefore: validBefore.toString(),
        nonce,
      },
    };
  }

  /**
   * Verify EIP-712 signature (for validation)
   * @param typedData EIP-712 typed data
   * @param signature Signature string or components
   * @param expectedSigner Expected signer address
   * @returns True if signature is valid
   */
  static verifySignature(
    typedData: any,
    signature: string | { v: number; r: string; s: string },
    expectedSigner: string
  ): boolean {
    try {
      // Compute EIP-712 hash
      const domain = typedData.domain;
      const types = { [typedData.primaryType]: typedData.types[typedData.primaryType] };
      const value = typedData.message;

      // Recover signer from signature
      let recoveredAddress: string;

      if (typeof signature === "string") {
        // Signature is a hex string
        const digest = ethers.TypedDataEncoder.hash(domain, types, value);
        recoveredAddress = ethers.recoverAddress(digest, signature);
      } else {
        // Signature has v, r, s components
        const digest = ethers.TypedDataEncoder.hash(domain, types, value);
        const signatureBytes = ethers.concat([
          signature.r,
          signature.s,
          ethers.toBeHex(signature.v, 1),
        ]);
        recoveredAddress = ethers.recoverAddress(digest, signatureBytes);
      }

      return recoveredAddress.toLowerCase() === expectedSigner.toLowerCase();
    } catch (error) {
      console.error("Signature verification failed:", error);
      return false;
    }
  }
}
