FROM n8nio/n8n:2.4.0

USER root

# ImageMagickとGhostscript（PDF処理に必要）をインストール
RUN apk add --no-cache \
    imagemagick \
    ghostscript

# ImageMagickのPDFセキュリティポリシーを緩和（PDF処理を許可）
RUN sed -i 's/<policy domain="coder" rights="none" pattern="PDF" \/>/<policy domain="coder" rights="read|write" pattern="PDF" \/>/g' /etc/ImageMagick-7/policy.xml || true

USER node

# デフォルトの起動コマンド
CMD ["n8n"]
