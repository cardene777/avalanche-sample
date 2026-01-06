import { ethers } from "ethers";
import { DispatchChainClient } from "./dispatch-chain";

/**
 * Payment Settler Service
 * PaymentRegistryへの決済記録とICMメッセージ送信
 */
export class PaymentSettler {
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
   * PaymentRegistryに支払いを記録
   * @param buyer 購入者アドレス
   * @param contentId コンテンツID
   * @param amount 支払い額
   * @param paymentTxHash 支払いトランザクションハッシュ
   * @returns トランザクションレシート
   */
  async settlePayment(
    buyer: string,
    contentId: string,
    amount: bigint,
    paymentTxHash: string
  ): Promise<ethers.TransactionReceipt> {
    console.log("Settling payment in PaymentRegistry:", {
      buyer,
      contentId,
      amount: amount.toString(),
      paymentTxHash,
    });

    // PaymentRegistry.settlePayment()を呼び出し
    // これによりICMメッセージがEcho Chainに送信される
    const receipt = await this.dispatchClient.settlePayment(
      buyer,
      contentId,
      amount,
      paymentTxHash,
      this.facilitatorWallet // Facilitatorがガス代を支払う
    );

    console.log("Payment settled successfully:", {
      transactionHash: receipt.hash,
      blockNumber: receipt.blockNumber,
    });

    return receipt;
  }

  /**
   * 支払い記録を確認
   * @param buyer 購入者アドレス
   * @param contentId コンテンツID
   * @returns 支払い記録（存在しない場合はnull）
   */
  async getPaymentRecord(buyer: string, contentId: string) {
    return await this.dispatchClient.getPaymentRecord(buyer, contentId);
  }

  /**
   * Facilitatorウォレットのアドレスを取得
   * @returns Facilitatorアドレス
   */
  getAddress(): string {
    return this.facilitatorWallet.address;
  }
}
