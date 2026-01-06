/**
 * Payment Authorization Request
 * フロントエンドから送信される支払い認証リクエスト
 */
export interface PaymentAuthorizationRequest {
  /**
   * 支払い元（ユーザー）
   */
  from: string;

  /**
   * 支払い先（コンテンツプロバイダー）
   */
  to: string;

  /**
   * 支払い額（文字列形式のbigint）
   */
  value: string;

  /**
   * 有効期間開始（Unix timestamp）
   */
  validAfter: string;

  /**
   * 有効期間終了（Unix timestamp）
   */
  validBefore: string;

  /**
   * 一意のnonce（bytes32）
   */
  nonce: string;

  /**
   * EIP-712署名
   */
  signature: {
    v: number;
    r: string;
    s: string;
  };

  /**
   * コンテンツID（記録用、オプション）
   */
  contentId?: string;
}

/**
 * Payment Authorization Response
 * Facilitatorからの支払い処理結果
 */
export interface PaymentAuthorizationResponse {
  /**
   * 処理成功フラグ
   */
  success: boolean;

  /**
   * トランザクションハッシュ
   */
  transactionHash: string;

  /**
   * ブロック番号
   */
  blockNumber: number;

  /**
   * PaymentRegistryへの決済記録が完了したか
   */
  paymentSettled: boolean;

  /**
   * メッセージ
   */
  message: string;
}

/**
 * Payment Status
 * 支払いステータス確認用
 */
export interface PaymentStatus {
  /**
   * トランザクションハッシュ
   */
  transactionHash: string;

  /**
   * ステータス
   */
  status: "pending" | "confirmed" | "failed";

  /**
   * ブロック番号
   */
  blockNumber?: number;

  /**
   * タイムスタンプ
   */
  timestamp?: number;

  /**
   * 支払い元
   */
  from: string;

  /**
   * 支払い先
   */
  to: string;

  /**
   * 金額
   */
  amount: string;

  /**
   * PaymentRegistryに記録済みか
   */
  settled: boolean;
}
