import { Router, Request, Response } from "express";
import { PaymentExecutor } from "../services/payment-executor";
import { PaymentSettler } from "../services/payment-settler";
import {
  PaymentAuthorizationRequest,
  PaymentAuthorizationResponse,
  PaymentStatus,
} from "../types/payment";

/**
 * Payment API Router
 * ガス代不要の支払い処理エンドポイント
 */
export function createPaymentRouter(
  paymentExecutor: PaymentExecutor,
  paymentSettler: PaymentSettler
): Router {
  const router = Router();

  // トランザクション記録（メモリ）
  // 本番環境ではRedisやデータベースを使用
  const transactionStore = new Map<
    string,
    PaymentStatus & { contentId?: string }
  >();

  /**
   * POST /api/payment/authorize
   * 支払い認証を受け付けて処理
   */
  router.post("/authorize", async (req: Request, res: Response) => {
    try {
      const authRequest: PaymentAuthorizationRequest = req.body;

      console.log("Received payment authorization request:", {
        from: authRequest.from,
        to: authRequest.to,
        value: authRequest.value,
        contentId: authRequest.contentId,
      });

      // 1. transferWithAuthorization実行
      const paymentReceipt = await paymentExecutor.executePayment(authRequest);

      // 2. PaymentRegistryに記録
      const settlementReceipt = await paymentSettler.settlePayment(
        authRequest.from,
        authRequest.contentId || "unknown",
        BigInt(authRequest.value),
        paymentReceipt.hash
      );

      // 3. トランザクション記録を保存
      const status: PaymentStatus & { contentId?: string } = {
        transactionHash: paymentReceipt.hash,
        status: "confirmed",
        blockNumber: paymentReceipt.blockNumber,
        timestamp: Math.floor(Date.now() / 1000),
        from: authRequest.from,
        to: authRequest.to,
        amount: authRequest.value,
        settled: true,
        contentId: authRequest.contentId,
      };
      transactionStore.set(paymentReceipt.hash, status);

      // 4. レスポンス返却
      const response: PaymentAuthorizationResponse = {
        success: true,
        transactionHash: paymentReceipt.hash,
        blockNumber: paymentReceipt.blockNumber,
        paymentSettled: true,
        message: "Payment processed successfully",
      };

      return res.status(200).json(response);
    } catch (error) {
      console.error("Payment authorization failed:", error);

      // エラーの種類に応じたステータスコード
      if (error instanceof Error) {
        if (error.message.includes("Nonce already used")) {
          return res.status(409).json({
            error: "Nonce already used",
            message: "This payment authorization has already been processed",
          });
        }
        if (
          error.message.includes("Invalid") ||
          error.message.includes("Insufficient")
        ) {
          return res.status(400).json({
            error: "Invalid request",
            message: error.message,
          });
        }
      }

      return res.status(500).json({
        error: "Transaction failed",
        message:
          error instanceof Error
            ? error.message
            : "Failed to process payment authorization",
      });
    }
  });

  /**
   * GET /api/payment/status/:txHash
   * トランザクションハッシュから支払いステータスを確認
   */
  router.get("/status/:txHash", async (req: Request, res: Response) => {
    try {
      const txHash = req.params.txHash;

      // メモリから取得
      const status = transactionStore.get(txHash);

      if (!status) {
        return res.status(404).json({
          error: "Transaction not found",
          message: `No payment found with transaction hash: ${txHash}`,
        });
      }

      return res.status(200).json(status);
    } catch (error) {
      console.error("Error fetching payment status:", error);
      return res.status(500).json({
        error: "Internal server error",
        message: "Failed to fetch payment status",
      });
    }
  });

  /**
   * GET /api/payment/record/:buyer/:contentId
   * PaymentRegistryから支払い記録を取得
   */
  router.get(
    "/record/:buyer/:contentId",
    async (req: Request, res: Response) => {
      try {
        const { buyer, contentId } = req.params;

        // アドレス検証
        if (!/^0x[a-fA-F0-9]{40}$/.test(buyer)) {
          return res.status(400).json({
            error: "Invalid buyer address",
            message: "Buyer address must be a valid Ethereum address",
          });
        }

        // PaymentRegistryから取得
        const record = await paymentSettler.getPaymentRecord(buyer, contentId);

        if (!record) {
          return res.status(404).json({
            error: "Payment not found",
            message: `No payment record found for buyer ${buyer} and content ${contentId}`,
          });
        }

        return res.status(200).json({
          buyer: record.buyer,
          contentId: record.contentId,
          amount: record.amount.toString(),
          paymentTxHash: record.paymentTxHash,
          settledAt: record.settledAt.toString(),
        });
      } catch (error) {
        console.error("Error fetching payment record:", error);
        return res.status(500).json({
          error: "Internal server error",
          message: "Failed to fetch payment record",
        });
      }
    }
  );

  return router;
}
