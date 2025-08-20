#!/bin/bash
# complete-ictt-workflow.sh

set -e

echo "=========================================="
echo "ICTT 完全ワークフロー実行"
echo "=========================================="

# 色付きメッセージ用の関数
print_step() {
    echo -e "\n\033[1;34m==> $1\033[0m"
}

print_success() {
    echo -e "\033[1;32m✓ $1\033[0m"
}

print_warning() {
    echo -e "\033[1;33m⚠ $1\033[0m"
}

print_error() {
    echo -e "\033[1;31m✗ $1\033[0m"
}

# 引数確認
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "ICTT完全ワークフロー自動実行スクリプト"
    echo ""
    echo "使用方法: $0 [options]"
    echo ""
    echo "このスクリプトは以下を順次実行します:"
    echo "1. 事前確認（ネットワーク、AWM Relayer状況）"
    echo "2. 初期残高確認"
    echo "3. トークンMint（対話式）"
    echo "4. Mint後残高確認"
    echo "5. クロスチェーン転送（対話式）"
    echo "6. 転送完了待機"
    echo "7. 最終残高確認"
    echo ""
    echo "オプション:"
    echo "  --skip-checks    事前確認をスキップ"
    echo "  --auto-wait N    転送待機時間を指定（デフォルト: 15秒）"
    echo "  --help, -h       このヘルプを表示"
    exit 0
fi

# オプション解析
SKIP_CHECKS=false
WAIT_TIME=15

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-checks)
            SKIP_CHECKS=true
            shift
            ;;
        --auto-wait)
            WAIT_TIME="$2"
            shift 2
            ;;
        *)
            print_error "不明なオプション: $1"
            echo "使用方法については --help を参照してください"
            exit 1
            ;;
    esac
done

print_step "1. 事前状況確認"

if [ "$SKIP_CHECKS" = false ]; then
    # ネットワーク確認
    echo "ネットワーク状況確認中..."
    NODE_COUNT=$(ps aux | grep avalanchego | grep -v grep | wc -l | tr -d ' ')
    echo "  Avalanche ノード数: $NODE_COUNT"
    
    if [ $NODE_COUNT -lt 4 ]; then
        print_warning "ノード数が少ない可能性があります（期待値: 4以上）"
        read -p "続行しますか？ (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "処理を中断しました"
            exit 1
        fi
    else
        print_success "ネットワーク状況OK"
    fi
    
    # AWM Relayer確認
    echo "AWM Relayer状況確認中..."
    RELAYER_COUNT=$(ps aux | grep icm-relayer | grep -v grep | wc -l | tr -d ' ')
    echo "  AWM Relayer プロセス数: $RELAYER_COUNT"
    
    if [ $RELAYER_COUNT -eq 0 ]; then
        print_warning "AWM Relayerが起動していません"
        echo "クロスチェーン転送には AWM Relayer が必要です"
        read -p "続行しますか？ (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "処理を中断しました"
            exit 1
        fi
    else
        print_success "AWM Relayer状況OK"
    fi
    
    # ICTT状況確認
    echo "ICTT設定確認中..."
    if command -v avalanche &> /dev/null; then
        print_success "avalanche CLI 利用可能"
    else
        print_error "avalanche CLI が見つかりません"
        exit 1
    fi
else
    print_warning "事前確認をスキップしました"
fi

print_step "2. 初期残高確認"
echo "現在の残高状況:"
avalanche key list --local --keys ewoq || {
    print_error "初期残高確認に失敗しました"
    echo "ネットワークの起動状況とキーの設定を確認してください"
    exit 1
}

print_step "3. トークンMint"
print_warning "対話式プロンプトが表示されます"
echo ""
echo "以下の選択肢で進めてください:"
echo "1. 'Mint tokens' を選択"
echo "2. 'Local Network' を選択"
echo "3. 適切なHome Bridgeアドレスを入力"
echo "4. 受信アドレスを入力（通常: 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC）"
echo "5. Mint量を入力（例: 1000000）"
echo ""
read -p "準備ができたら Enter キーを押してください..." -r

if avalanche key transfer --local; then
    print_success "Mint処理完了"
else
    print_error "Mint処理でエラーが発生しました"
    echo "設定を確認して再実行してください"
    exit 1
fi

print_step "4. Mint後の残高確認"
echo "Mint後の残高状況:"
avalanche key list --local --keys ewoq

print_step "5. クロスチェーン転送"
print_warning "再度対話式プロンプトが表示されます"
echo ""
echo "以下の選択肢で進めてください:"
echo "1. 'Transfer tokens via Teleporter' を選択"
echo "2. 'Local Network' を選択"
echo "3. 送信元チェーンを選択（例: C-Chain）"
echo "4. 送信先チェーンを選択（例: chain1）"
echo "5. Home Bridge と Remote Bridge アドレスを入力"
echo "6. 送信者キーを選択（例: ewoq）"
echo "7. 受信者アドレスを入力"
echo "8. 転送量を入力"
echo ""
read -p "準備ができたら Enter キーを押してください..." -r

if avalanche key transfer --local; then
    print_success "転送処理開始"
else
    print_error "転送処理でエラーが発生しました"
    echo "設定を確認して再実行してください"
    exit 1
fi

print_step "6. 転送完了待機"
echo "転送完了を待機中..."
echo "AWM Relayerのログをモニタリングします（${WAIT_TIME}秒間）"

# AWM Relayerログの監視
LOG_FILE="$HOME/awm-relayer-direct.log"
if [ -f "$LOG_FILE" ]; then
    echo "ログファイル: $LOG_FILE"
    
    # バックグラウンドでログ監視
    timeout $WAIT_TIME tail -f "$LOG_FILE" | grep --line-buffered "Delivered message" &
    LOG_PID=$!
    
    # 指定時間待機
    sleep $WAIT_TIME
    
    # ログ監視プロセスを停止
    kill $LOG_PID 2>/dev/null || true
    
    # 最近のログから転送完了を確認
    if tail -n 50 "$LOG_FILE" | grep -q "Delivered message"; then
        print_success "転送完了を確認しました"
    else
        print_warning "転送完了の確認ができませんでした"
        echo "手動でログを確認してください: tail -f $LOG_FILE"
    fi
else
    print_warning "AWM Relayerログファイルが見つかりません"
    echo "手動で転送状況を確認してください"
fi

print_step "7. 最終残高確認"
echo "転送後の残高状況:"
avalanche key list --local --keys ewoq

print_step "ワークフロー完了!"
print_success "すべての処理が完了しました"
echo ""
echo "次のステップ:"
echo "1. 詳細な残高確認: ./scripts/check-token-balance.sh"
echo "2. AWM Relayerログ確認: tail -f ~/awm-relayer-direct.log"
echo "3. 追加転送: avalanche key transfer --local"
echo ""
echo "トラブルシューティングが必要な場合:"
echo "- ICTT_TOKEN_WORKFLOW.md を参照"
echo "- AWM Relayerログで詳細エラーを確認"
echo "- ネットワークとノードの状況を確認"
echo ""
echo "=========================================="