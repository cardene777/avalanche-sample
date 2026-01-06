import { ethers } from "ethers";
import { DispatchChainClient } from "./dispatch-chain";
import { PaymentAuthorizationRequest } from "../types/payment";

/**
 * Payment Executor Service
 * ERC-3009トランザクションを実行し、支払いを処理
 */
export class PaymentExecutor {
  private dispatchClient: DispatchChainClient;
  private facilitatorWallet: ethers.Wallet;

  constructor(
    dispatchClient: DispatchChainClient,
    facilitatorPrivateKey: string,
    provider: ethers.JsonRpcProvider
  ) {
    this.dispatchClient = dispatchClient;
    this.facilitatorWallet = new ethers.Wallet(facilitatorPrivateKey, provider);
  }

  /**
   * 支払い認証を検証して実行
   * @param request 支払い認証リクエスト
   * @returns トランザクションレシート
   */
  async executePayment(
    request: PaymentAuthorizationRequest
  ): Promise<ethers.TransactionReceipt> {
    // 1. パラメータのバリデーション
    this.validateRequest(request);

    // 2. Nonce重複確認
    const nonceUsed = await this.dispatchClient.isNonceUsed(
      request.from,
      request.nonce
    );
    if (nonceUsed) {
      throw new Error("Nonce already used");
    }

    // 3. 有効期限確認
    const now = Math.floor(Date.now() / 1000);
    const validAfter = BigInt(request.validAfter);
    const validBefore = BigInt(request.validBefore);

    if (BigInt(now) < validAfter) {
      throw new Error("Authorization not yet valid");
    }
    if (BigInt(now) > validBefore) {
      throw new Error("Authorization expired");
    }

    // 4. 残高確認
    const balance = await this.dispatchClient.getBalance(request.from);
    const value = BigInt(request.value);
    if (balance < value) {
      throw new Error("Insufficient balance");
    }

    // 5. transferWithAuthorization実行
    console.log("Executing transferWithAuthorization:", {
      from: request.from,
      to: request.to,
      value: request.value,
      nonce: request.nonce,
    });

    const receipt = await this.dispatchClient.transferWithAuthorization(
      request.from,
      request.to,
      value,
      validAfter,
      validBefore,
      request.nonce,
      request.signature,
      this.facilitatorWallet // Facilitatorがガス代を支払う
    );

    console.log("Payment executed successfully:", {
      transactionHash: receipt.hash,
      blockNumber: receipt.blockNumber,
    });

    return receipt;
  }

  /**
   * リクエストのバリデーション
   * @param request 支払い認証リクエスト
   */
  private validateRequest(request: PaymentAuthorizationRequest): void {
    // アドレス検証
    if (!ethers.isAddress(request.from)) {
      throw new Error("Invalid 'from' address");
    }
    if (!ethers.isAddress(request.to)) {
      throw new Error("Invalid 'to' address");
    }

    // 金額検証
    try {
      const value = BigInt(request.value);
      if (value <= 0n) {
        throw new Error("Value must be greater than 0");
      }
    } catch {
      throw new Error("Invalid 'value' format");
    }

    // タイムスタンプ検証
    try {
      BigInt(request.validAfter);
      BigInt(request.validBefore);
    } catch {
      throw new Error("Invalid timestamp format");
    }

    // Nonce検証（bytes32）
    if (!/^0x[a-fA-F0-9]{64}$/.test(request.nonce)) {
      throw new Error("Invalid nonce format (must be bytes32)");
    }

    // 署名検証
    if (!request.signature || typeof request.signature.v !== "number") {
      throw new Error("Invalid signature format");
    }
    if (!/^0x[a-fA-F0-9]{64}$/.test(request.signature.r)) {
      throw new Error("Invalid signature.r format");
    }
    if (!/^0x[a-fA-F0-9]{64}$/.test(request.signature.s)) {
      throw new Error("Invalid signature.s format");
    }
  }

  /**
   * Facilitatorウォレットのアドレスを取得
   * @returns Facilitatorアドレス
   */
  getAddress(): string {
    return this.facilitatorWallet.address;
  }

  /**
   * Facilitatorウォレットの残高を取得
   * @returns 残高（ETH換算）
   */
  async getBalance(): Promise<bigint> {
    return await this.facilitatorWallet.provider!.getBalance(
      this.facilitatorWallet.address
    );
  }
}
